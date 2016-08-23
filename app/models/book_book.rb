class BookBook < ActiveRecord::Base
  self.table_name='magritte.legami_libri'
  belongs_to :book_from, class_name:'Book', foreign_key:'enum_from'
  belongs_to :book_to, class_name:'Book', foreign_key:'enum_to'
  
  
end
