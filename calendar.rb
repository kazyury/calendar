#!ruby -Ks

require "date"
require "default_holidays"

class CalendarFormatError < RuntimeError ; end
class UnexpectedCalendarFormatter < RuntimeError ; end

class DefaultFormatter

	def initialize
		@width = 5 # ���ɕ��ׂ�J�����_�̐�
	end
	attr_accessor :width
	
#	�������Ƃ��Ă��炤�̂�Calendar�̔z��
	def format(cals , io=STDOUT)
		while true
			cal_number=cals.size # �c�\���v�J�����_�[��
			break if cal_number==0

			count= @width > cal_number ? cal_number : @width #���̍s�ɉ������\�����邩
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
		cal_line.each{|calendar| io.printf("%-33s","#{calendar.yyyy}�N#{calendar.mm}��") }
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
	# yyyy	�F�N
	# mm		�F��
	# dd		�F��
	# wday	�F�j��(0�F���j�`6:�y�j)
	# holiday	�F�x���^�j���̏ꍇ�Atrue
	# desc		�F�j���̏ꍇ�A���̖���
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
			# �����̋x���Ή�
			# �O��������̏j���ɋ��܂ꂽ�����́A�����̋x��
			#
			# �U��ւ��x���Ή�
			# ���j���������̏j���ƂȂ����ꍇ�A���̒���́u�����̋x���v�ȊO�̓�
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
		# �����̃`�F�b�N�ƔN���̐ݒ�
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
		
		@calendar=[] # �J�����_�f�[�^�̊i�[��

		# �J�����_�̍쐬
		prepare_calendar
	end
	attr_reader :yyyy , :mm , :calendar

	# �T�̐���ԋp����B
	def size
		@calendar.size
	end

	# idx�Ԗڂ̏T�̃f�[�^��z��ŕԋp����B
	# �z��̒��g�́A���l(���j����n�܂�A���̏T�̓��t)
	def [](idx)
		@calendar[idx].map{|w| w ?  w.dd : nil } if @calendar[idx]
	end

	# idx�Ԗڂ̏T�̃f�[�^��z��ŕԋp����B
	# �z��̒��g�́ACalendarDay�I�u�W�F�N�g�̔z��
	def week(idx)
		@calendar[idx]
	end


	:private
	def prepare_calendar
		raise "[Bug] @yyyy or @mm is nil" unless @yyyy && @mm

		if Date.new(@yyyy,@mm,1).wday == 1 # ���j���̏ꍇ
			monday_count=1
		else
			monday_count=0
		end

		cal=CalendarDay.new(Date.new(@yyyy,@mm,1),monday_count) # Date�N���X�͑�3�������w�肵�Ȃ���΁A1������n�܂邯�ǔO�̂���
		

		buf_week=Array.new(7,nil)
		while true
			if cal.wday==0 # ���j���ɂȂ�����o�b�t�@���N���A
				if buf_week.any? # ����ł��o�b�t�@���ɓ��t�������Ă����
					@calendar.push buf_week
				end
				buf_week=Array.new(7,nil) 
			end

			# ���j���̎��͌��j���ł���B
			# dirty code
			if cal.wday==0
				monday_count+=1
			end

			buf_week[cal.wday] = cal
			cal = cal.next(monday_count)

			if cal.mm != @mm  # ���̌��ɂȂ�����
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
	
	# formatter�����[�h����
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

	# �o��
	def format
		@calendars.sort!{|a,b| sprintf("%4s%02s",a.yyyy,a.mm) <=> sprintf("%4s%02s",b.yyyy,b.mm)}
		@formatter.format(@calendars)
	end

end

# todo
# �����̋x���Ή��A�U��ւ��x���Ή�
