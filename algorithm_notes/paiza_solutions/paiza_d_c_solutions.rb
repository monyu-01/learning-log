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

# 入力された番号と当選番号を比べて、当たりの種類を判定するプログラム
def problem19
  b = gets.to_i
  n = gets.to_i
  a = n.times.map { gets.to_i }
  
  a.each do |e|
    result = 'blank'  # はずれを初期値として代入
  
    if e == b
      result = 'first'            # 完全一致
    elsif e + 1 == b || e - 1 == b
      result = 'adjacent'         # 前後1番違い
    elsif e % 10_000 == b % 10_000
      result = 'second'           # 下4桁一致
    elsif e % 1000 == b % 1000
      result = 'third'            # 下3桁一致
    end
  
    puts result
  end
end

# 投球結果の表示
# strike か ball の結果が与えられ、strike の場合は "!" をつけて出力。
def problem20
  n = gets.to_i
  n.times do 
    s = gets.chomp
    if s == "ball"
        puts s
    else
        puts s + "!"
    end
  end
end

# strike数のカウント表示
# strike が来るたびにカウントアップし、何回目の strike! かを表示する。ball の場合はそのまま表示。
def problem21
  n = gets.to_i
  count = 0
  
  n.times do
      s = gets.chomp
      if s == "strike"
          count += 1
          puts s + "!"
          puts count
      else
          puts "ball"
      end
  end
end

# 3ストライクで out!
# strike が3回になった時に "out!" を出力。それまでは strike! を出力。ball の場合はそのまま表示。
def problem22
  n = gets.to_i
  count = 0
  
  n.times do
    s = gets.chomp
    if s == "ball"
      puts s
    elsif s == "strike"
      count += 1
      if count == 3
        puts "out!"
      else
        puts "strike!"
      end
    end
  end
end