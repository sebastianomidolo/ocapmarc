class Book < ActiveRecord::Base
  # attr_accessible :title, :body
  self.table_name='magritte.storage_libri'
  self.primary_key='enum'

  has_many :items, foreign_key:'enum'
  has_many :author_titles, foreign_key:'enum_titolo'
  has_many :authors, through: :author_titles

  def title
    Book.estrai_campo('ti',self.enum)
  end

  def df
    Book.estrai_campo('df',self.enum)
  end

  def no
    Book.estrai_campo('no',self.enum)
  end


  def to_marc21
    record = MARC::Record.new()
    record.append(MARC::DataField.new('245', '0',  ' ', ['a', self.title]))
    record.append(MARC::DataField.new('300', '0',  ' ', ['a', self.df]))
    record
  end

  def to_unimarc
    record = MARC::Record.new()
    record.append(MARC::DataField.new('200', '0',  ' ', ['a', self.title]))
    record.append(MARC::DataField.new('215', '0',  ' ', ['a', self.df]))
    record.append(MARC::DataField.new('300', '0',  ' ', ['a', self.no]))
    self.items.each do |i|
      record.append(MARC::DataField.new('995', ' ',  ' ', ['k', i.collocazione]))
    end
    record
  end


  def Book.estrai_campo(label,record_enum)
    sql="select estrai_campo_ocap(ocap_reclist,'#{label}') as rv FROM #{Book.table_name} WHERE enum=#{record_enum}"
    Book.connection.execute(sql)[0]['rv']
  end


end
