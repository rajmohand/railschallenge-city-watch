class Responder < ActiveRecord::Base
  # type reserved word
  # Test has it so included
  self.inheritance_column = :_type

  RESPONDER_TYPES = %w(Fire Medical Police)

  scope :of_type,     -> (type)     { where(type: type) }
  scope :unassigned,  ->            { where(emergency_code: nil) }
  scope :on_duty,     ->            { where(on_duty: true) }
  scope :available,   ->            { on_duty.unassigned }

  #abs allways to give posite value
  scope :appropriate, -> (severity) { order("abs(capacity - #{severity}) asc") }
  scope :capable_of,  -> (severity) { where('capacity >= ?', severity) }

  validates :capacity, presence: true, inclusion: { in: 1..5 }
  validates :name,     presence: true, uniqueness: { case_sensitive: false }
  validates :type,     presence: true

  def assign_code(code)
    update_attribute(:emergency_code, code)
  end

  def self.allocate_responders(type, severity, code)
    best_responder = most_appropriate_for(type, severity)
    if best_responder
      best_responder.assign_code(code)
      return true
    else
      assign_responders(type, severity, code)
    end
  end

  def self.capacities_for(type)
    capacities = []
    responders = of_type(type)
    capacities << capacity_of(responders)
    capacities << capacity_of(responders.unassigned)
    capacities << capacity_of(responders.on_duty)
    capacities << capacity_of(responders.available)
  end

  def self.dispatch_to(emergency)
    responses = []
    RESPONDER_TYPES.each do |type|
      severity = emergency.send("#{type.downcase}_severity")
      responses << allocate_responders(type, severity, emergency.code)
    end
    emergency.confirm_full_response if responses.all?
  end

  def self.emergency_capacities
    capacities = {}
    RESPONDER_TYPES.each do |type|
      capacities[type] = capacities_for(type)
    end
    capacities
  end

  def self.assign_responders(type, severity, code)
    while severity > 0
      responders = of_type(type).available.appropriate(severity)
      return false unless responders.any?
      responder = responders.first
      responder.assign_code(code)
      severity -= responder.capacity
    end
    true
  end

  def self.most_appropriate_for(type, severity)
    return nil if severity == 0
    of_type(type).available.capable_of(severity).appropriate(severity).first
  end

  def self.capacity_of(responders)
    responders.sum(:capacity)
  end
end
