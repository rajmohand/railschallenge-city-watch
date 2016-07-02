class Emergency < ActiveRecord::Base
  has_many :responders, foreign_key: :emergency_code, primary_key: :code
end
