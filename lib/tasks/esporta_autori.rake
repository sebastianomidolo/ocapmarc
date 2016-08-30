# -*- mode: ruby;-*-

desc 'Esporta dati autori'

task :esporta_autori => :environment do
  fname="/tmp/autori.mrc"
  writer = MARC::Writer.new(fname)


  enums = ENV['enums']
  if enums.blank?
    primo_enum=1
    ultimo_enum=Author.count
  else
    primo_enum,ultimo_enum=enums.split('-')
  end

  cnt=0
  Author.find_each(start:primo_enum,finish:ultimo_enum).each do |a|
    cnt+=1
    puts "enum autore #{a.enum} => #{a.heading}"
    writer.write(a.to_unimarc)
  end
  
  writer.close()
  puts "Esportati #{cnt} autori, da enum #{primo_enum} a enum #{ultimo_enum}"
  puts "su file #{fname} (#{File.size(fname)} bytes)"
  File.chown(nil, 33, fname)
end
