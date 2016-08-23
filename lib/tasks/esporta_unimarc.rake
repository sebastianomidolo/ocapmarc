# -*- mode: ruby;-*-

desc 'Esporta dati ocap in unimarc'

task :esporta_unimarc => :environment do
  fname="/tmp/unimarc.dat"
  writer = MARC::Writer.new(fname)


  primo_enum=1444
  ultimo_enum=1500
  
  Book.where("estrai_campo_ocap(ocap_reclist,'nat')='S'").find_each(start:primo_enum,finish:ultimo_enum).each do |b|
    puts "enum #{b.enum} [#{b.nat}] => #{b.title}"
    writer.write(b.to_unimarc)
  end
  
  writer.close()
  puts "OK scritto #{fname} (#{File.size(fname)} bytes)"
end


