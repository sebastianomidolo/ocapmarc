class AuthorTitle < ActiveRecord::Base
  self.table_name='magritte.legami_autoretitolo'
  belongs_to :book, foreign_key:'enum_titolo'
  belongs_to :author, foreign_key:'enum_autore'
end
