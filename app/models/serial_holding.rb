class SerialHolding < ActiveRecord::Base
  self.table_name='magritte.consistenze_periodici'
  self.primary_key='enum'

  belongs_to :book, foreign_key:'enum'
end
