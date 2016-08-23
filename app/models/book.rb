class Book < ActiveRecord::Base
  self.table_name='magritte.storage_libri'
  self.primary_key='enum'

  has_many :items, foreign_key:'enum'
  has_many :author_titles, foreign_key:'enum_titolo'
  has_many :authors, through: :author_titles

  has_many :book_book_from, foreign_key:'enum_from', class_name:'BookBook'
  has_many :book_book_to, foreign_key:'enum_to', class_name:'BookBook'
  has_many :titoli_contenuti, class_name:'Book', through: :book_book_from, source:'book_to'
  has_many :titoli_legati, class_name:'Book', through: :book_book_to, source:'book_from'

  has_one :serial_holding, foreign_key:'enum'
  
  def title
    Book.estrai_campo('ti',self.enum)
  end

  def df
    Book.estrai_campo('df',self.enum)
  end

  def no
    Book.estrai_campi('no',self.enum)
  end

  def nat
    Book.estrai_campo('nat',self.enum)
    sql="select public.estrai_natura_ocap(ocap_reclist) as rv FROM #{Book.table_name} WHERE enum=#{self.id}"
    Book.connection.execute(sql)[0]['rv']
  end

  def to_unimarc
    record = MARC::Record.new()
    record.append(MARC::DataField.new('200', '0',  ' ', ['a', self.title]))
    record.append(MARC::DataField.new('215', '0',  ' ', ['a', self.df]))
    self.no.each do |nota|
      puts "nota: #{nota}"
      record.append(MARC::DataField.new('300', '0',  ' ', ['a', nota]))
    end
    if !self.serial_holding.nil?
      puts "holding: #{self.serial_holding.inspect}"
      puts "consistenza #{self.serial_holding.consistenza}"
    end
    self.items.each do |i|
      record.append(MARC::DataField.new('995', ' ',  ' ', ['k', i.collocazione]))
    end
    record
  end

  def Book.estrai_campo(label,record_enum)
    sql="select public.estrai_campo_ocap(ocap_reclist,'#{label}') as rv FROM #{Book.table_name} WHERE enum=#{record_enum}"
    Book.connection.execute(sql)[0]['rv']
  end

  def Book.estrai_campi(label,record_enum)
    sql="select public.estrai_campi_ocap(ocap_reclist,'#{label}') as rv FROM #{Book.table_name} WHERE enum=#{record_enum}"
    s=Book.connection.execute(sql)[0]['rv']
    return [] if s.nil?
    s.split(/\{([^}]*)\}/).reject { |c| c.blank? }
  end

end
