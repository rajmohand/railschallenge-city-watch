class Emergency < ActiveRecord::Base
  has_many :responders, foreign_key: :emergency_code, primary_key: :code

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :police_severity, :fire_severity, :medical_severity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def confirm_full_response
    update_attribute(:full_response, true)
  end

  def responder_names
    responders.pluck(:name)
  end

  def dismiss_responders
    responders.clear if resolved_at && resolved_at < Time.zone.now
  end
end
