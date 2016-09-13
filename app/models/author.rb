# coding: utf-8
class Author < ActiveRecord::Base
  self.table_name='magritte.storage_autori'
  self.primary_key='enum'

  has_many :author_titles, foreign_key:'enum_autore'
  has_many :books, through: :author_titles

  def heading
    Author.estrai_campo('item',self.enum)
  end

  def ctime
    Author.estrai_campo('ctime',self.enum)
  end

  def mtime
    Author.estrai_campo('mtime',self.enum)
  end
  
  # Formato del campo: 20040129122025 coop@217.133.12.156
  # Per estrarre la data faccio t.split.first
  # Cerco prima la data di ultima modifica e se questa manca uso quella di creazione (che assumo sempre presente)
  def date_updated_or_date_created
    t=self.mtime
    t=self.ctime if t.blank?
    t.split.first
  end

  def tipo
    tipo=Author.estrai_campo('tipo',self.enum)
    if tipo.blank?
      # puts "non trovato tipo per autore #{self.id} - #{self.heading}"
      # Tiro a indovinare: se l'intestazione contiene una sola virgola, assumo tipo "0" (autore personale)
      # se non ci sono virgole o se ce ne sono due o più, assumo "1" (autore ente)
      v=self.heading.count(',')
      tipo=v==1 ? '0' : '1'
    end
    tipo
  end

  def unimarc_005
    self.date_updated_or_date_created
  end

  def unimarc_100
    data_registrazione=self.date_updated_or_date_created[0..7]
    "#{data_registrazione}0itay50      ba"
    #        8901234567890123456789012345
    #          1---------2---------3-----
  end

  def to_unimarc
    record = MARC::Record.new()
    record.leader[5]='n'
    record.leader[6]='z'
    record.append(MARC::ControlField.new('001', self.id.to_s))
    record.append(MARC::ControlField.new('005', self.unimarc_005))
    record.append(MARC::DataField.new('100', ' ',  ' ', ['a', self.unimarc_100]))
    t = self.tipo=='1' ? 'CO' : 'NP'
    record.append(MARC::DataField.new('152', ' ',  ' ', ['b', t]))
    record.append(MARC::DataField.new('200', ' ',  ' ', ['a', self.heading]))
    puts "#{self.id} [#{t}] => #{self.heading}"
    record
  end
  
  def Author.estrai_campo(label,record_enum)
    sql="select estrai_campo_ocap(ocap_reclist,'#{label}') as rv FROM #{Author.table_name} WHERE enum=#{record_enum}"
    Author.connection.execute(sql)[0]['rv']
  end

end
