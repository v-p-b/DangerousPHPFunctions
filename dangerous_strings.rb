#!/usr/bin/env ruby

require 'rubygems'
require 'find'
require 'optparse'


class OptsParse

  def self.parse(cmds)
    options = {}
    OptionParser.new do |opt|
      
      opt.on("-d", "-d <directory>", "path to the directory to search. ex: /var/www/") do |d|
	    options['dir'] = d
      end
      
      opt.on("-o", "-o <out file>", "File to output results to. ex: /var/www/myfile.txt") do |o|
	    options['outfile'] = o
      end     
	
      opt.on_tail("-h", "--help", "Show this message") do
       puts opt
       exit
      end
        
      begin
       opt.parse!(cmds)
     rescue OptionParser::InvalidOption
      puts "\e[1;31m[error]\e[0m Invalid option, try -h for usage"
      exit
     rescue OptionParser::MissingArgument
      puts "\e[1;31m[error]\e[0m You are missing an argument"
      exit
     end
	
    end
   options
  end
    
end

class ProgressBar
  VERSION = "0.9"

  def initialize (title, total, out = STDERR)
    @title = title
    @total = total
    @out = out
    @terminal_width = 80
    @bar_mark = "="
    @current = 0
    @previous = 0
    @finished_p = false
    @start_time = Time.now
    @previous_time = @start_time
    @title_width = 14
    @format = "%-#{@title_width}s %3d%% %s %s"
    @format_arguments = [:title, :percentage, :bar, :stat]
    clear
    show
  end
  attr_reader   :title
  attr_reader   :current
  attr_reader   :total
  attr_accessor :start_time
  attr_writer   :bar_mark

  private
  def fmt_bar
    bar_width = do_percentage * @terminal_width / 100
    sprintf("|%s%s|", 
            @bar_mark * bar_width, 
            " " *  (@terminal_width - bar_width))
  end

  def fmt_percentage
    do_percentage
  end

  def fmt_stat
    if @finished_p then elapsed else eta end
  end

  def fmt_stat_for_file_transfer
    if @finished_p then 
      sprintf("%s %s %s", bytes, transfer_rate, elapsed)
    else 
      sprintf("%s %s %s", bytes, transfer_rate, eta)
    end
  end

  def fmt_title
    @title[0,(@title_width - 1)] + ":"
  end

  def convert_bytes (bytes)
    if bytes < 1024
      sprintf("%6dB", bytes)
    elsif bytes < 1024 * 1000 # 1000kb
      sprintf("%5.1fKB", bytes.to_f / 1024)
    elsif bytes < 1024 * 1024 * 1000  # 1000mb
      sprintf("%5.1fMB", bytes.to_f / 1024 / 1024)
    else
      sprintf("%5.1fGB", bytes.to_f / 1024 / 1024 / 1024)
    end
  end

  def transfer_rate
    bytes_per_second = @current.to_f / (Time.now - @start_time)
    sprintf("%s/s", convert_bytes(bytes_per_second))
  end

  def bytes
    convert_bytes(@current)
  end

  def format_time (t)
    t = t.to_i
    sec = t % 60
    min  = (t / 60) % 60
    hour = t / 3600
    sprintf("%02d:%02d:%02d", hour, min, sec);
  end

  # ETA stands for Estimated Time of Arrival.
  def eta
    if @current == 0
      "ETA:  --:--:--"
    else
      elapsed = Time.now - @start_time
      eta = elapsed * @total / @current - elapsed;
      sprintf("ETA:  %s", format_time(eta))
    end
  end

  def elapsed
    elapsed = Time.now - @start_time
    sprintf("Time: %s", format_time(elapsed))
  end
  
  def eol
    if @finished_p then "\n" else "\r" end
  end

  def do_percentage
    if @total.zero?
      100
    else
      @current  * 100 / @total
    end
  end

  def get_width
    # FIXME: I don't know how portable it is.
    default_width = 80
    begin
      tiocgwinsz = 0x5413
      data = [0, 0, 0, 0].pack("SSSS")
      if @out.ioctl(tiocgwinsz, data) >= 0 then
        rows, cols, xpixels, ypixels = data.unpack("SSSS")
        if cols >= 0 then cols else default_width end
      else
        default_width
      end
    rescue Exception
      default_width
    end
  end

  def show
    arguments = @format_arguments.map {|method| 
      method = sprintf("fmt_%s", method)
      send(method)
    }
    line = sprintf(@format, *arguments)

    width = get_width
    if line.length == width - 1 
      @out.print(line + eol)
      @out.flush
    elsif line.length >= width
      @terminal_width = [@terminal_width - (line.length - width + 1), 0].max
      if @terminal_width == 0 then @out.print(line + eol) else show end
    else # line.length < width - 1
      @terminal_width += width - line.length + 1
      show
    end
    @previous_time = Time.now
  end

  def show_if_needed
    if @total.zero?
      cur_percentage = 100
      prev_percentage = 0
    else
      cur_percentage  = (@current  * 100 / @total).to_i
      prev_percentage = (@previous * 100 / @total).to_i
    end

    # Use "!=" instead of ">" to support negative changes
    if cur_percentage != prev_percentage || 
        Time.now - @previous_time >= 1 || @finished_p
      show
    end
  end

  public
  def clear
    @out.print "\r"
    @out.print(" " * (get_width - 1))
    @out.print "\r"
  end

  def finish
    @current = @total
    @finished_p = true
    show
  end

  def finished?
    @finished_p
  end

  def file_transfer_mode
    @format_arguments = [:title, :percentage, :bar, :stat_for_file_transfer]
  end

  def format= (format)
    @format = format
  end

  def format_arguments= (arguments)
    @format_arguments = arguments
  end

  def halt
    @finished_p = true
    show
  end

  def inc (step = 1)
    @current += step
    @current = @total if @current > @total
    show_if_needed
    @previous = @current
  end

  def set (count)
    if count < 0 || count > @total
      raise "invalid count: #{count} (total: #{@total})"
    end
    @current = count
    show_if_needed
    @previous = @current
  end

  def inspect
    "#<ProgressBar:#{@current}/#{@total}>"
  end
end

class ReversedProgressBar < ProgressBar
  def do_percentage
    100 - super
  end
end


dangerous_strings_array = []

dangerous_strings = [ 
  "shell_exec",
  "passthru",
  "exec",
  "pnctl_exec",
  "proc_open",
  "popen",
  "system",
  "shell_exec",
  "register_shutdown_function",
  "register_tick_function",
  "dl",
  "eval",
]



options = OptsParse.parse(ARGV)
dir = options['dir']
outfile = options ['outfile']
banner = "\e[1;31m[Usage]\e[0m dangerous_strings.rb -d /var/www/myphpapp/ -o ~/results.txt"

[dir, outfile].each do |item|
  if item.nil?
    puts banner
    exit
  end
end


file_arry = []

if File.directory?(dir)
  Find.find(dir) { |file|
    if file.to_s =~ (/(.\php|.txt)/) and File.directory?(file) == false
      file_arry.push(file)
    end  
  }
else
 puts "\e[1;31m[error]\e[0m The directory you entered does not exist"
 exit
end


pbar = ProgressBar.new("Processing", file_arry.length)
index = 0
file_arry.each_with_index do |f, idx|
  index = idx + 1
 # sleep(0.1)
  pbar.set(index)
  open_file = File.open(f, "r")
  open_file.each {|line|
    dangerous_strings.each do |str|
      if line.include?(str)
       dangerous_strings_array << ([f.to_s,line.to_s,str.to_s])
      end
    end
  }  
end
pbar.finish

if File.exists?(outfile)
  File.delete(outfile)
end

  file_write = File.open(outfile, "a")
  dangerous_strings_array.each do |item|
      fname = item[0]
      interesting_line = item[1]
      ds = item[2]
      file_write.puts("\n#{fname} (#{ds})\n" + "=" * fname.length + "\n"  +"#{interesting_line}\n")
    end

  