#!ruby -Ks

require "date"
require "default_holidays"

class CalendarFormatError < RuntimeError ; end
class UnexpectedCalendarFormatter < RuntimeError ; end

class DefaultFormatter

	def initialize
		@width = 5 # 横に並べるカレンダの数
	end
	attr_accessor :width
	
#	第一引数としてもらうのはCalendarの配列
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

class Calendar
	# yyyy	：年
	# mm		：月
	# dd		：日
	# wday	：曜日(0：日曜～6:土曜)
	# holiday	：休日／祝日の場合、true
	# desc		：祝日の場合、その名称
	class CalendarDay

		def initialize(date,wnum)
			@date=date
			@yyyy,@mm,@dd,@wday = date.year , date.month , date.day , date.wday
			@wnum=wnum
			@holiday=false
			@holiday=true if @wday==0 || @wday==6

			@desc=nil
			DEFAULT_HOLIDAYS.each{|holiday|
				if eval("#{holiday[:constraint]}")
					@holiday=true
					@desc=holiday[:desc] 
				end
			}
			# 国民の休日対応
			# 前後を国民の祝日に挟まれた平日は、国民の休日
			#
			# 振り替え休日対応
			# 日曜日が国民の祝日となった場合、その直後の「国民の休日」以外の日
			#
#			p "#{@yyyy}-#{@mm}-#{@dd} wday:#{@wday} wnum:#{@wnum}"
		end
		attr_reader :yyyy , :mm , :dd , :wday , :holiday , :desc

		def holiday?
			@holiday
		end

		def next(wnum)
			CalendarDay.new(@date.next,wnum)
		end
	end

	def initialize(yyyy=nil , mm=nil)
		# 引数のチェックと年月の設定
		today=Date.today
		if yyyy
			raise CalendarFormatError.new("$1 needs YYYY format,but was #{yyyy}") if /\D/=~yyyy.to_s
			@yyyy=yyyy.to_i
		else
			@yyyy=today.year
		end
		if mm
			raise CalendarFormatError.new("$2 needs MM format(1-12),but was #{mm}") if /\D/=~mm.to_s || (mm.to_i < 1) || (mm.to_i > 12)
			@mm=mm.to_i
		else
			@mm=today.month
		end
		
		@calendar=[] # カレンダデータの格納先

		# カレンダの作成
		prepare_calendar
	end
	attr_reader :yyyy , :mm , :calendar

	# 週の数を返却する。
	def size
		@calendar.size
	end

	# idx番目の週のデータを配列で返却する。
	# 配列の中身は、数値(日曜から始まる、その週の日付)
	def [](idx)
		@calendar[idx].map{|w| w ?  w.dd : nil } if @calendar[idx]
	end

	# idx番目の週のデータを配列で返却する。
	# 配列の中身は、CalendarDayオブジェクトの配列
	def week(idx)
		@calendar[idx]
	end


	:private
	def prepare_calendar
		raise "[Bug] @yyyy or @mm is nil" unless @yyyy && @mm

		if Date.new(@yyyy,@mm,1).wday == 1 # 月曜日の場合
			monday_count=1
		else
			monday_count=0
		end

		cal=CalendarDay.new(Date.new(@yyyy,@mm,1),monday_count) # Dateクラスは第3引数を指定しなければ、1日から始まるけど念のため
		

		buf_week=Array.new(7,nil)
		while true
			if cal.wday==0 # 日曜日になったらバッファをクリア
				if buf_week.any? # 一日でもバッファ内に日付が入っていれば
					@calendar.push buf_week
				end
				buf_week=Array.new(7,nil) 
			end

			# 日曜日の次は月曜日でしょ。
			# dirty code
			if cal.wday==0
				monday_count+=1
			end

			buf_week[cal.wday] = cal
			cal = cal.next(monday_count)

			if cal.mm != @mm  # 次の月になったら
				@calendar.push buf_week
				break
			end
		end
	end

end

class CalendarList

	def initialize(yyyy=nil , mm=nil , formatter="Default")
		@formatter = load_formatter(formatter)
		@calendars=[]
		append(yyyy,mm)
	end
	attr_reader :formatter , :calendars

	def append(yyyy=nil , mm=nil)
		cal=Calendar.new(yyyy , mm)
		@calendars.push cal unless @calendars.find{|v| v.yyyy == cal.yyyy && v.mm == cal.mm }
	end
	
	# formatterをロードする
	def load_formatter(formatter)
		if formatter=="Default"
			formatter=DefaultFormatter.new
		else
			src="formatter/#{formatter.downcase}.rb"
			if File.exist?(src)
				load src
				formatter=eval("#{formatter}.new")
			else
				raise UnexpectedCalendarFormatter.new("not exist #{src}.")
			end
			formatter
		end
	end

	# 出力
	def format
		@calendars.sort!{|a,b| sprintf("%4s%02s",a.yyyy,a.mm) <=> sprintf("%4s%02s",b.yyyy,b.mm)}
		@formatter.format(@calendars)
	end

end

# todo
# 国民の休日対応、振り替え休日対応
