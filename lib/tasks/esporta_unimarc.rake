# coding: utf-8
# -*- mode: ruby;-*-

desc 'Esporta dati ocap in unimarc'


# Esempi:
#    rake esporta_unimarc nat=S enums=1-100
#    rake esporta_unimarc nat=NS enums=200-300


task :esporta_unimarc => :environment do
  nat = ENV['nat']
  nat='BCMNPS' if nat.blank?

  bib_levels=nat.split('').collect {|x| "'#{x}'"}.join(',')
  
  enums = ENV['enums']
  if enums.blank?
    primo_enum=1
    ultimo_enum=Book.count
  else
    primo_enum,ultimo_enum=enums.split('-')
  end

  fname="/tmp/unimarc_#{nat.downcase}.mrc"
  writer = MARC::Writer.new(fname)

  cnt=0
  Book.where("public.estrai_natura_ocap(ocap_reclist) IN(#{bib_levels})").find_each(start:primo_enum,finish:ultimo_enum).each do |b|
    puts "enum #{b.enum} [#{b.nat}] => #{b.title}"
    cnt+=1
    writer.write(b.to_unimarc)
  end
  writer.close()

  puts "Esportati #{cnt} records #{nat}, da enum #{primo_enum} a enum #{ultimo_enum}"
  puts "Su file #{fname} (#{File.size(fname)} bytes)"
  File.chown(nil, 33, fname)
end


