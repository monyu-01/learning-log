def problem1
  h, w, a, b = gets.split.map(&:to_i)
  (1..h).each do |i|
    line = (1..w).map { "(#{a}, #{b})" }.join(" | ")
    puts line
    puts "=" * line.size if i < h
  end
end

def problem2
  h, w, a, b = gets.split.map(&:to_i)
  (1..h).each do |i|
    line = (1..w).map { "(%9d, %9d)" % [a, b] }.join(" | ")
    puts line
    puts "=" * line.size if i < h
  end
end

def problem3
  1000.times { puts gets }
end

def problem4
  _n = gets.to_i # 読むだけ
  a = gets.split
  puts a
end

def problem5
  _n, *a = gets.split.map(&:to_i) # 読むだけ
  puts a
end

def problem6
  _n, *a = gets.split.map(&:chomp) # 読むだけ
  puts a
end

def problem7
  _n = gets.to_i # 読むだけ
  puts gets.split
end

def problem8
  n = gets.to_i
  n.times do
    puts gets.to_f
  end
end

def problem9
  n = gets.to_i
  n.times do |i|
    a, b = gets.split.map(&:to_i)
    if i == 7
      puts "#{a} #{b}"
    end
  end
end

def problem10
  n = gets.to_i
  n.times do 
    s, a = gets.split
    puts "#{s} #{a}"
  end
end

problem1