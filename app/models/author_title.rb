# coding: utf-8
class AuthorTitle < ActiveRecord::Base
  self.table_name='magritte.legami_autoretitolo'
  belongs_to :book, foreign_key:'enum_titolo'
  belongs_to :author, foreign_key:'enum_autore'

  # 700 Autore personale - responsabilità principale (Non ripetibile)
  # 701 Autore personale - responsabilità alternativa (Ripetibile)
  # 702 Autore personale - responsabilità secondaria (Ripetibile)
  # 710 Ente collettivo - responsabilità principale (Non ripetibile)
  # 711 Ente collettivo - responsabilità alternativa (Ripetibile)
  # 712 Ente collettivo - responsabilità secondaria (Ripetibile)
  def unimarc_tag
    if self.author.nil?
      puts "Autore non controllato: #{self.noncontrollato}"
      # Vedi Author#tipo
      v=self.noncontrollato.count(',')
      tipo=v==1 ? '0' : '1'
    else
      tipo=self.author.tipo
    end
    resp=self.livelloresp.blank? ? 2 : self.livelloresp - 1
    "7#{tipo}#{resp}"
  end
end
