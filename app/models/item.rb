class Item < ActiveRecord::Base
  # attr_accessible :title, :body
  self.table_name='magritte.copie'

  belongs_to :book, foreign_key:'enum'
end
