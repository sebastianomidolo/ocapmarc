class Author < ActiveRecord::Base
  self.table_name='magritte.storage_autori'
  self.primary_key='enum'

  has_many :author_titles, foreign_key:'enum_autore'
  has_many :books, through: :author_titles

  def heading
    Author.estrai_campo('item',self.enum)
  end

  def Author.estrai_campo(label,record_enum)
    sql="select estrai_campo_ocap(ocap_reclist,'#{label}') as rv FROM #{Author.table_name} WHERE enum=#{record_enum}"
    Author.connection.execute(sql)[0]['rv']
  end

end
