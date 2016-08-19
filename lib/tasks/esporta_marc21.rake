# -*- mode: ruby;-*-

desc 'Esporta dati ocap in marc21'

task :esporta_marc21 => :environment do
  writer = MARC::Writer.new('marc.dat')
  
  Book.all(limit:100,order:'enum desc').each do |b|
    puts b.enum
    writer.write(b.to_marc21)
  end
  
  writer.close()
  puts "OK scritto marc21.dat"
end


