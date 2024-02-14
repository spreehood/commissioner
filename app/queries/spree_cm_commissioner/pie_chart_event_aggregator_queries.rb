module SpreeCmCommissioner
  class PieChartEventAggregatorQueries
    attr_reader :taxon_id, :chart_type, :refreshed

    # chart_type: 'participation | gender | entry_type' taxon_id: taxon_id, refreshed: false
    def initialize(taxon_id:, chart_type:, refreshed: false)
      @taxon_id = taxon_id
      @chart_type = chart_type || 'participation'
      @refreshed = refreshed
    end

    def call
      cache_key = "#{chart_type}-#{taxon_id}"
      Rails.cache.delete(cache_key) if refreshed

      value = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        pie_chart_aggregators || []
      end

      SpreeCmCommissioner::PieChartEventAggregator.new(
        id: taxon_id,
        type: chart_type,
        value: value
      )
    end

    def pie_chart_aggregators
      case chart_type
      when 'participation' then participation_pie_chart
      when 'gender' then gender_pie_chart
      when 'entry_type' then entry_type_pie_chart
      end
    end

    private

    def base_joins
      SpreeCmCommissioner::Guest
        .joins('INNER JOIN cm_check_ins ON cm_check_ins.guest_id = cm_guests.id')
        .joins('INNER JOIN spree_line_items ON spree_line_items.id = cm_guests.line_item_id')
        .joins('INNER JOIN spree_variants ON spree_variants.id = spree_line_items.variant_id')
        .joins('INNER JOIN spree_orders ON spree_orders.id = spree_line_items.order_id')
        .joins('INNER JOIN spree_products ON spree_products.id = spree_variants.product_id')
        .joins('INNER JOIN spree_products_taxons ON spree_products.id = spree_products_taxons.product_id')
        .joins('INNER JOIN spree_taxons ON spree_taxons.id = spree_products_taxons.taxon_id')
        .where(spree_orders: { state: 'complete' }, spree_taxons: { parent_id: taxon_id })
    end

    def participation_pie_chart
      base_joins
        .select('spree_products.id AS product_id, COUNT(DISTINCT cm_check_ins.id) AS checked_in_ticket, COUNT(*) AS total_ticket')
        .group('spree_products.id')
        .map do |record|
          record.slice(:product_id, :checked_in_ticket, :total_ticket)
        end
    end

    def gender_pie_chart
      base_joins
        .select("CASE
                  WHEN cm_guests.gender = 0 THEN 'other'
                  WHEN cm_guests.gender = 1 THEN 'male'
                  WHEN cm_guests.gender = 2 THEN 'female'
                  ELSE NULL
                END AS genders, COUNT(DISTINCT cm_guests.id) AS gender_count"
               )
        .group('genders')
        .map do |record|
          record.slice(:genders, :gender_count)
        end
    end

    def entry_type_pie_chart
      base_joins
        .select("spree_products.id AS product_id, CASE WHEN cm_check_ins.entry_type = 0 THEN 'normal' WHEN cm_check_ins.entry_type = 1 THEN 'VIP' ELSE NULL END AS entry_types, COUNT(cm_check_ins.id) AS check_in_count") # rubocop:disable Layout/LineLength
        .where.not(cm_check_ins: { id: nil })
        .group('spree_products.id, entry_types')
        .map do |record|
          record.slice(:product_id, :entry_types, :check_in_count)
        end
    end
  end
end