#!ruby -Ks

class Default

	def initialize
		@width = 5 # 横に並べるカレンダの数
	end
	attr_accessor :width
	
	# 第一引数としてもらうのはCalendarの配列
	def format(cals , io=STDOUT)
		while true
			cal_number=cals.size # 残表示要カレンダー数
			break if cal_number==0

			count= @width > cal_number ? cal_number : @width #次の行に何月分表示するか
			next_line=[]
			count.times{ next_line.push cals.shift }

			print_header(next_line , io)
			print_wday(next_line , io)
			print_days(next_line , io)
			io.puts
		end
	end

	:private
	def print_header(cal_line , io)
		cal_line.each{|calendar| io.printf("%-33s","#{calendar.yyyy}年#{calendar.mm}月") }
		io.puts
	end

	def print_wday(cal_line , io)
		cal_line.size.times{
			%w(Sun Mon Tue Wed Thu Fri Sat).each{|wd| io.printf("%4s",wd) }
			io.printf("%4s","")
		}
		io.puts
	end

	def print_days(cal_line , io)
		lines=[]
		cal_line.each{|calendar| lines.push calendar.size }
		(0..lines.max).each{|idx|
			cal_line.each{|calendar|
				if calendar[idx]
					calendar.week(idx).each{|day|
						if day && day.holiday?
							io.printf("%4s","#{day.dd}*")
						elsif day
							io.printf("%4s",day.dd)
						else
							io.printf("%4s","")
						end
					}
					io.printf("%4s","")
				else
					io.printf("%32s","")
				end
			}
			io.puts
		}
	end

end

