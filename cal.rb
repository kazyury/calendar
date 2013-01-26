#!ruby -Ks

require "calendar"
require "optparse"

width=nil
range_mode=false

opt=OptionParser.new
opt.banner="#{$0} [options] yyyy-mm [yyyy-mm ... ]\n"
opt.banner+="�J�����_��\�����܂��B\n\n"
opt.on('-w WIDTH','--width=WIDTH','WIDTH���̌���1�s�ŕ\������B�f�t�H���g��5'){|w| width=w}
opt.on('-r','--range','�͈͎w��̏ꍇ�Ɏw�肷��B'){|v| range_mode=true }
opt.on('-h','--help','show this message'){|v| puts opt ; exit }
opt.parse!(ARGV)

if ARGV.size==0
	cal=CalendarList.new
else
	yyyy,mm=ARGV.shift.split('-')
	cal=CalendarList.new(yyyy,mm)

	if range_mode
		buffer=[]
		buffer.push sprintf("%4i%02i",yyyy.to_i,mm.to_i)
		ARGV.each{|arg|
			yyyy,mm=arg.split('-')
			buffer.push sprintf("%4i%02i",yyyy.to_i,mm.to_i)
		}
		buffer.min.upto(buffer.max){|b|
			yyyy=b[0..3]
			mm=b[4..5]
			unless  mm > "12" || mm == "00"
				cal.append(yyyy,mm)
			end
		}
	else
		ARGV.each{|arg|
			yyyy,mm=arg.split('-')
			cal.append(yyyy,mm)
		}
	end
end
cal.formatter.width=width.to_i if /\d/=~width
cal.format

