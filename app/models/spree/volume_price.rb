class Spree::VolumePrice < Spree::Base

  belongs_to :variant, touch: true, require: false
  belongs_to :volume_price_model, touch: true, require: false
  belongs_to :spree_role, class_name: 'Spree::Role', foreign_key: 'role_id', require: false

  acts_as_list scope: [:variant_id, :volume_price_model_id]

  validates :amount, presence: true
  validates :discount_type,
            presence: true,
            inclusion: {
              in: %w(price),
              message: I18n.t('activerecord.errors.messages.is_not_included_in_the_list')
            }
  validates :range_format

  def self.for_variant(variant, user: nil)
    roles = [nil]
    if user
      roles << user.resolve_role.try!(:id)
    end

    where(
      arel_table[:variant_id].eq(variant.id).
      or(
        arel_table[:volume_price_model_id].in(variant.volume_price_model_ids)
      )
    ).
    where(role_id: roles).
    order(position: :asc, amount: :asc)
  end

  def include?(quantity)
    range_from_string.include?(quantity)
  end

  def display_range
    range.gsub(/\.+/, "-").gsub(/\(|\)/, '')
  end

  private

  def range_format
    if !(OpenVolumePricing::RangeFromString::RANGE_FORMAT =~ range ||
         OpenVolumePricing::RangeFromString::OPEN_ENDED =~ range)
      errors.add(:range, :must_be_in_format)
    end
  end

  def range_from_string
    OpenVolumePricing::RangeFromString.new(range).to_range
  end
end