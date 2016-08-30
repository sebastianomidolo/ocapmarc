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
  
  def ctime
    Book.estrai_campo('ctime',self.enum)
  end

  def title
    Book.estrai_campo('ti',self.enum)
  end

  def df
    Book.estrai_campo('df',self.enum)
  end

  def no
    Book.estrai_campi('no',self.enum)
  end

  def nopr
    Book.estrai_campi('nopr',self.enum)
  end

  def nat # S periodico, M monografia, N spoglio, W 
    Book.estrai_campo('nat',self.enum)
    sql="select public.estrai_natura_ocap(ocap_reclist) as rv FROM #{Book.table_name} WHERE enum=#{self.id}"
    Book.connection.execute(sql)[0]['rv']
  end

  def plpuye
    Book.estrai_campo('plpuye',self.enum)
  end

  def url
    Book.estrai_campo('url',self.enum)
  end

  def luogo_edizione
    return nil if self.plpuye.nil?
    self.plpuye.split(/,|:/).first  
  end

  def editore_edizione
    return nil if self.plpuye.nil?
    ed = self.plpuye.split(/,|:/,2).last
    return nil if ed.nil?
    ed.split(/,/).first 
  end

  def anno_edizione
    return nil if self.plpuye.nil?
    ed = self.plpuye.split(/,|:/,2).last
    return nil if ed.nil?
    ed.split(/,/).last 
  end

  def to_unimarc
    record = MARC::Record.new()
    puts "enum: #{enum}"
    #puts "ctime: #{ctime.split(' ').first}"
    # indico con #sist le righe sicuramente da sistemare
    # 099$c ctime
    record.append(MARC::DataField.new('099', '0',  ' ', ['c', self.ctime.split(' ').first]))

    # 090$a enum
    record.append(MARC::DataField.new('090', '0',  ' ', ['a', self.enum.to_s]))

    # 101$a Lingua
    record.append(MARC::DataField.new('101', '0',  ' ', ['a', "ita"]))

    # 101$a Paese
    record.append(MARC::DataField.new('102', '0',  ' ', ['a', "IT"]))

    # 200$a title ??
    record.append(MARC::DataField.new('200', '1',  ' ', ['a', self.title]))

    # 210$a luogo_edizione
    if !self.luogo_edizione.nil?
      record.append(MARC::DataField.new('210', '1',  ' ', ['a', luogo_edizione]))
    end

    # 210$c editore_edizione
    if !self.editore_edizione.nil?
      record.append(MARC::DataField.new('210', '1',  ' ', ['c', editore_edizione]))
    end

    # 210$d anno_edizione
    if !self.anno_edizione.nil?
      record.append(MARC::DataField.new('210', '1',  ' ', ['d', anno_edizione]))
    end

    # 215$d df
    record.append(MARC::DataField.new('215', '0',  ' ', ['d', self.df]))

    # 300$a note
    self.no.each do |nota|
      #puts "nota: #{nota}"
      record.append(MARC::DataField.new('300', '0',  ' ', ['a', nota]))
    end

    # 300$a consistenza (qui non so mai se mettterlo a livello di BIBLIO o di ITEM... 
    if !self.serial_holding.nil?
      #puts "holding: #{self.serial_holding.inspect}"
      #puts "consistenza #{self.serial_holding.consistenza}"
      record.append(MARC::DataField.new('300', '0',  ' ', ['a', "Posseduto: #{self.serial_holding.consistenza}"]))
    end

    # 200$f autore ??
    # 700$a autore
    # 700$b ulteriore elemento del nome
    # 701 autore
    # 702 autore

    self.author_titles.each do |at|
      puts "at: #{at.inspect}"
      au=at.author
      # Da perfezionare tenendo conto della casistica:
      tag = at.livelloresp=='1' ? '700' : '702'
      data_field=MARC::DataField.new(tag, ' ',  '1')
      data_field.subfields << MARC::Subfield.new('a',au.heading)
      data_field.subfields << MARC::Subfield.new('9',au.id.to_s)
      record.append(data_field)
    end

    # 326$a nopr
    self.no.each do |nopr|
      record.append(MARC::DataField.new('326', '',  ' ', ['a', nopr]))
    end

    # 500$a title
    record.append(MARC::DataField.new('500', '1',  ' ', ['a', self.title]))

    # 801$a 
    record.append(MARC::DataField.new('801', ' ',  '0', ['a', "IT"]))
    # 801$b 
    record.append(MARC::DataField.new('801', ' ',  '0', ['b', "APM-OCAP ("+self.ctime.split(' ').last+")"]))
    # 801$c
    record.append(MARC::DataField.new('801', ' ',  '0', ['c', self.ctime.split(' ').first]))
    # 801$f 
    record.append(MARC::DataField.new('801', ' ',  '0', ['f', "OCAP"]))

    # 856$1 URL
    record.append(MARC::DataField.new('856', '4',  ' ', ['1', self.url]))
		
    # 942$c  nat : M => BK, S => CR, N => ??  #sist
    record.append(MARC::DataField.new('856', '4',  ' ', ['1', self.nat]))

    #  SEZIONE 995 (ITEM)
    self.items.each do |i|

      data_field=MARC::DataField.new('995', ' ',  ' ')

      # 995$0 default
      data_field.subfields << MARC::Subfield.new('0','1')
			
      # 995$2 default			
      data_field.subfields << MARC::Subfield.new('2', '0')

      # 995$3 default
      data_field.subfields << MARC::Subfield.new('3', '1')
      
      # 995$5 default
      data_field.subfields << MARC::Subfield.new('6', '1')

      # 995$6 default			
      data_field.subfields << MARC::Subfield.new('2', '0')

      # 995$7 URL (anche in BIBLIO)
      data_field.subfields << MARC::Subfield.new('7', self.url)

      # 995$a 
      data_field.subfields << MARC::Subfield.new('a', "Archivio Primo Moroni")

      # 995$b 
      data_field.subfields << MARC::Subfield.new('b', "APM001")

      # 995$c 
      data_field.subfields << MARC::Subfield.new('c', "APM001")

      # 995$k collocazione			
      data_field.subfields << MARC::Subfield.new('k', i.collocazione)

      # 995$f ctime
      data_field.subfields << MARC::Subfield.new('f', self.ctime.split(' ').first)
      
      # 995$o nat
      data_field.subfields << MARC::Subfield.new('o', '1')

      # 995$r nat : M => BK, S => CR, N => ??  #sist
      data_field.subfields << MARC::Subfield.new('r', self.nat)
      
      # 995$u I FONDI (rimando) P7 "Fondo Sergio Spazzali" / P9 "Fondo Roberto Volponi"  #sist
      data_field.subfields << MARC::Subfield.new('r', self.nat)

      record.append(data_field)
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
