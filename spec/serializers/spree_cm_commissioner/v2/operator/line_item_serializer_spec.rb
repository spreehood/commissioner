require 'spec_helper'

RSpec.describe SpreeCmCommissioner::V2::Operator::LineItemSerializer, type: :serializer do
  describe '#serializable_hash' do
    let!(:order) { create(:order) }
    let!(:line_item) { create(:line_item, order: order) }
    let!(:guest) { create(:guest, line_item: line_item) }

    subject {
      described_class.new(line_item, include: [
        :order,
        :guests,
      ]).serializable_hash
    }

    it 'returns exact line_item attributes' do
      expect(subject[:data][:attributes].keys).to contain_exactly(
        :number,
        :name,
        :quantity,
        :options_text,
        :qr_data,
      )

      expect(subject[:data][:attributes][:name]).to eq line_item.name
      expect(subject[:data][:attributes][:quantity]).to eq line_item.quantity
      expect(subject[:data][:attributes][:options_text]).to eq line_item.options_text
    end

    it 'returns exact line_item relationships' do
      expect(subject[:data][:relationships].keys).to contain_exactly(
        :order,
        :guests,
        :variant
      )

      order = subject[:included].find { |item| item[:type] == :order }
      expect(order[:attributes].keys).to contain_exactly(:email, :number, :phone_number, :state, :qr_data, :item_count)

      guest = subject[:included].find { |item| item[:type] == :guest }
      expect(guest[:attributes].keys).to contain_exactly(:dob, :event_id, :first_name, :gender, :last_name, :qr_data, :seat_number, :formatted_bib_number, :phone_number)
    end
  end
end
