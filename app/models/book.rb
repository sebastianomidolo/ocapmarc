# coding: utf-8
class Book < ActiveRecord::Base
  self.table_name='magritte.storage_libri'
  self.primary_key='enum'

  has_many :items, foreign_key:'enum'
  has_many :author_titles, foreign_key:'enum_titolo'
  has_many :authors, through: :author_titles

  has_many :book_book_from, foreign_key:'enum_to', class_name:'BookBook'
  has_many :book_book_to, foreign_key:'enum_from', class_name:'BookBook'
  has_many :titoli_contenuti, class_name:'Book', through: :book_book_from, source:'book_to'
  has_many :titoli_legati, class_name:'Book', through: :book_book_to, source:'book_from'

  has_one :serial_holding, foreign_key:'enum'
  
  def ctime
    Book.estrai_campo('ctime',self.enum)
  end

  def ctimeTime
    self.ctime.split(' ').first
  end

  def ctimeUser
    self.ctime.split(' ').last
  end

  def title  # rimuovo gli asterischi nel titolo
    a = Book.estrai_campo('ti',self.enum)
    a.gsub("*", "")
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

  def leader_bib_level
    h={'M'=>'m','N'=>'a','S'=>'s','C'=>'c'}
    v=h[self.db_nat]
    v.nil? ? 'm' : v
  end

  def db_nat # S periodico, M monografia, N spoglio
    sql="select public.estrai_natura_ocap(ocap_reclist) as rv FROM #{Book.table_name} WHERE enum=#{self.id}"
    Book.connection.execute(sql)[0]['rv']
  end

  def nat
    #B (20) Titolo di raggruppamento non controllato
    #C (1) Collezione
    #M (6122) Monografie = BK
    #N (834) Spogli
    #P (1) Titolo parallelo
    #S (966) Periodici = CR
    #U (2) Soggetto
    case self.db_nat
    when "M"
      "BK"
    when "S"
      "CR"
    else
      puts "natura indefinita " + self.db_nat
      self.db_nat
    end
  end

  def plpuye
    Book.estrai_campo('plpuye',self.enum)
  end

  def url
    Book.estrai_campo('url',self.enum)
  end

  def luogo_edizione
    return nil if self.plpuye.nil?
    v=self.plpuye.split(/,|:/).first
    v.blank? ? nil : v.strip
  end

  def editore_edizione
    return nil if self.plpuye.nil?
    ed = self.plpuye.split(/,|:/,2).last
    return nil if ed.nil?
    v=ed.split(/,/).first
    v.blank? ? nil : v.strip
  end

  def anno_edizione
    return nil if self.plpuye.nil?
    ed = self.plpuye.split(/,|:/,2).last
    return nil if ed.nil?
    v=ed.split(/,/).last
    v.blank? ? nil : v.strip    
  end

  def rec100a
    '20161001         u||y0itay50'
  end

  def to_unimarc
    record = MARC::Record.new()
    puts "enum: #{enum}"

    # http://unimarc-it.wikidot.com/leader
    # [5 - Status]
    # [6 - Tipo di record]
    # [7 - Livello bibliografico]
    record.leader[5]='n'
    record.leader[6]='a'
    record.leader[7]=self.leader_bib_level

    # 001
    record.append(MARC::ControlField.new('001', self.enum.to_s))

    # 090$a enum
    record.append(MARC::DataField.new('090', '0',  ' ', ['a', self.enum.to_s]))

    # 099$c ctime
    record.append(MARC::DataField.new('099', '0',  ' ', ['c', self.ctimeTime]))

    # 100$a
    record.append(MARC::DataField.new('100', '0',  ' ', ['a', rec100a]))
    
    # 101$a Lingua
    record.append(MARC::DataField.new('101', '0',  ' ', ['a', "ita"]))

    # 101$a Paese
    record.append(MARC::DataField.new('102', '0',  ' ', ['a', "IT"]))

    # 200$a title [il 200 per Koha è obbligatorio]
    record.append(MARC::DataField.new('200', '1',  ' ', ['a', self.title]))


    # SEZIONE 210
    data_field=MARC::DataField.new('210', '1',  '')
    is210=false
 
   # 210$a luogo_edizione
    if !self.luogo_edizione.nil?
      data_field.subfields << MARC::Subfield.new('a',luogo_edizione)
      is201=true
      #record.append(MARC::DataField.new('210', '1',  ' ', ['a', luogo_edizione]))
    end

    # 210$c editore_edizione
    if !self.editore_edizione.nil?
      is201=true
      data_field.subfields << MARC::Subfield.new('c',editore_edizione)
      #record.append(MARC::DataField.new('210', '1',  ' ', ['c', editore_edizione]))
    end

    # 210$d anno_edizione
    if !self.anno_edizione.nil?
      is201=true
      data_field.subfields << MARC::Subfield.new('d',anno_edizione)
      #record.append(MARC::DataField.new('210', '1',  ' ', ['d', anno_edizione]))
    end

    if (is201) 					
      record.append(data_field)
    end
    # FINE sezione 210

    # 215$d df
    record.append(MARC::DataField.new('215', '0',  ' ', ['d', self.df]))

    # 300$a note
    self.no.each do |nota|
      #puts "nota: #{nota}"
      record.append(MARC::DataField.new('300', '0',  ' ', ['a', nota]))
    end

    # 300$a consistenza  
    if !self.serial_holding.nil?
      #puts "holding: #{self.serial_holding.inspect}"
      #puts "consistenza #{self.serial_holding.consistenza}"
      record.append(MARC::DataField.new('300', '0',  ' ', ['a', "Posseduto: #{self.serial_holding.consistenza}"]))
    end

    self.author_titles.each do |at|
      data_field=MARC::DataField.new(at.unimarc_tag, ' ',  '1')
      if at.author.nil?
        # Autore non controllato
        data_field.subfields << MARC::Subfield.new('a',at.noncontrollato)

	# 200$f autore (metto tutti in 200$f mentre qualcuno potrebbe andare in 200$g) [il 200 per Koha è obbligatorio]
	if at.unimarc_tag == "700" or at.unimarc_tag == "710"
	  record.append(MARC::DataField.new('200', '0',  ' ', ['f', at.noncontrollato]))
        else
	  record.append(MARC::DataField.new('200', '0',  ' ', ['g', at.noncontrollato]))
	end
	record.append(data_field)
      else
        au=at.author				
	if au.id.to_s != "119" #Se Autore ha enum 119 non faccio nulla
          data_field.subfields << MARC::Subfield.new('a',au.heading)
  #        data_field.subfields << MARC::Subfield.new('9',au.id.to_s) --------------> provo senza il 9
	
  # 200$f autore (metto tutti in 200$f mentre qualcuno potrebbe andare in 200$g) [il 200 per Koha è obbligatorio]
          if at.unimarc_tag == "700" or at.unimarc_tag == "710"
	    record.append(MARC::DataField.new('200', '0',  ' ', ['f', au.heading]))
	  else
	    record.append(MARC::DataField.new('200', '0',  ' ', ['g', au.heading]))
	  end
	    record.append(data_field)
        end
     end
    end

    # 326$a nopr
    self.nopr.each do |nopr|
      record.append(MARC::DataField.new('326', '',  ' ', ['a', nopr]))
    end

    # 500$a title
    record.append(MARC::DataField.new('500', '1',  ' ', ['a', self.title]))
		
    # 801 SEZIONE 801 
    data_field=MARC::DataField.new('801', ' ',  ' ')
    data_field.subfields << MARC::Subfield.new('a','IT')
    data_field.subfields << MARC::Subfield.new('b','APM-OCAP ('+self.ctimeUser+')')
    data_field.subfields << MARC::Subfield.new('c',self.ctimeTime)
    data_field.subfields << MARC::Subfield.new('f','OCAP')
    record.append(data_field)
    # FINE sezione 801


    # 856$1 URL
    if self.url != "" 
      record.append(MARC::DataField.new('856', '4',  ' ', ['1', self.url]))
			record.append(MARC::DataField.new('856', '4',  ' ', ['3', 'PDF']))
    end
		
    # 942$c  nat
    record.append(MARC::DataField.new('942', ' ',  ' ', ['c', self.nat]))
    
    copia = 0

    #  SEZIONE 995 (ITEM)
    self.items.each do |i|

      data_field=MARC::DataField.new('995', ' ',  ' ')

      # 995$0 withdrown
      data_field.subfields << MARC::Subfield.new('0','0')
			
      # 995$2 copia smarrita
      data_field.subfields << MARC::Subfield.new('2', '0')

      # 995$3 restrizioni d'uso
      data_field.subfields << MARC::Subfield.new('3', '0')

      # 995$5 data inventario (yyyy-mm-dd)
      #data_field.subfields << MARC::Subfield.new('5', self.ctimeTime)

      # 995$6 numero della copia	
      copia += copia
      data_field.subfields << MARC::Subfield.new('2', copia.to_s)

      # 995$7 URL (anche in BIBLIO)
      if self.url!=""
			data_field.subfields << MARC::Subfield.new('7', self.url)
      end

      # 995$a 
      data_field.subfields << MARC::Subfield.new('a', "Archivio Primo Moroni")

      # 995$b 
      data_field.subfields << MARC::Subfield.new('b', "APM001")

      # 995$c 
      data_field.subfields << MARC::Subfield.new('c', "APM001")

			# 995$f (BARCODE) 
      data_field.subfields << MARC::Subfield.new('f', "2016-"+self.enum.to_s.rjust(4,"0"))

      # 995$k collocazione			
      data_field.subfields << MARC::Subfield.new('k', i.collocazione)
      
      # 995$o not for loan
      data_field.subfields << MARC::Subfield.new('o', '1')

      # 995$r nat 
      data_field.subfields << MARC::Subfield.new('r', self.nat)

      if !i.collocazione.nil?
        # 995$u I FONDI (rimando) P7 "Fondo Sergio Spazzali" / P9 "Fondo Roberto Volponi"  #sist
        fondo = i.collocazione[0,2]=="P7" ? "Fondo Sergio Spazzali" : (i.collocazione[0,2]=="P9" ? "Fondo Roberto Volponi" : "")
        if fondo != ""
      	  data_field.subfields << MARC::Subfield.new('u', fondo)
        end
      end
      record.append(data_field)
    end
    self.book_book_to.each do |bb|
      puts "Legame to   codice #{bb.codice} con enum #{bb.enum_to}: #{bb.book_to.title}"
    end
    self.book_book_from.each do |bb|
      puts "Legame from codice #{bb.codice} con enum #{bb.enum_from}: #{bb.book_from.title}"
      case bb.codice
      when '51'
        puts "Codice 51"
        target_book=bb.book_from
        data_field=MARC::DataField.new('461', ' ',  '0')
        data_field.subfields << MARC::Subfield.new('0', target_book.enum.to_s)
        data_field.subfields << MARC::Subfield.new('t', target_book.title)
        record.append(data_field)
      else
        puts "Codice di legame #{bb.codice} non trattato"
      end
    end
    record
  end
	#FINE SEZIONE 995  

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
