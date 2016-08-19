# -*- mode: ruby;-*-

desc 'Esporta dati ocap in unimarc'

task :esporta_unimarc => :environment do
  writer = MARC::Writer.new('unimarc.dat')
  
  Book.all(limit:30000,order:'enum desc').each do |b|
    # puts b.title
    writer.write(b.to_unimarc)
  end
  
  writer.close()
  puts "OK scritto unimarc.dat"
end


