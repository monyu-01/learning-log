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

def problem11
  require 'set'

  n = gets.to_i
  words = Array.new(n) { gets.chomp }
  
  # Set を使って重複を管理し、reverse_each で後ろから走査して
  # 初めて出た単語だけを出力する
  seen = Set.new
  words.reverse_each do |w|
    puts w if seen.add?(w)  
  end
end

def problem12
  s = gets.chomp.split
  puts s.include?("red") ? "Yes" : "No"
end

def problem13
  equire 'set'

  words = gets.chomp.split
  seen = Set.new

  words.each do |w|
    if seen.include?(w)
      # 同じ単語が出た場合は "already_been" と出力する
      puts "already_been"
    else
      puts w
      seen.add(w)
    end
  end
end

# 重複する単語を除いて最初に出た単語だけを出力する
def problem14
  require 'set'

  words = gets.split
  seen = Set.new
  
  words.each do |w|
     unless seen.include?(w)
         puts w
         seen.add(w)
     end
  end
end

# 指定した単語が何番目（0始まり）に出現するかを出力する
def problem15
  words = gets.split
  s = gets.chomp
  puts words.index(s) 
end

# 入力された単語を数え、各単語とその出現回数を出力するプログラム
def problem16
  words = gets.split
  counts = words.tally  
  
  counts.each_key { |w| puts w }
  counts.each_value { |c| puts c }
end

# 入力された単語を数え、各単語とその出現回数をセットで出力するプログラム
# Hashを使って手動でカウントする方法
def problem17
  words = gets.split
  counts = Hash.new(0)
  
  words.each { |w| counts[w] += 1 }
  counts.each do |word, count|
    puts "#{word} #{count}"
  end
end

# tallyメソッドを使って自動でカウントする方法
def problem18
  words = gets.split
  counts = words.tally
  
  counts.each do |word, count|
    puts "#{word} #{count}"
  end
end