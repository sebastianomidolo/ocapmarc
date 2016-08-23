# -*- mode: ruby;-*-

desc 'Esporta dati ocap in unimarc'

task :esporta_unimarc => :environment do
  fname="/tmp/unimarc.dat"
  writer = MARC::Writer.new(fname)


  Book.find_each(start:1,finish:100).each do |b|
    puts "enum #{b.enum} => #{b.title}"
    writer.write(b.to_unimarc)
  end
  
  writer.close()
  puts "OK scritto #{fname} (#{File.size(fname)} bytes)"
end


