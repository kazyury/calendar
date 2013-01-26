#!ruby -Ks

class Default

	def initialize
		@width = 5 # ���ɕ��ׂ�J�����_�̐�
	end
	attr_accessor :width
	
	# �������Ƃ��Ă��炤�̂�Calendar�̔z��
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

