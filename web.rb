require 'scorched'
require 'haml'
require 'calendarium-romanum'
require 'yaml'

module ChurchCalendar
  class Web < Scorched::Controller
    include CalendariumRomanum

    config << {
      static_dir: 'public'
    }
    render_defaults << {
      layout: :_layout,
      engine: :haml
    }

    get '/' do
      render :index
    end

    get '/browse' do
      start_year = Time.now.year - 5
      end_year = start_year + 10
      l = {start_year: start_year, end_year: end_year, today: Date.today}
      render :browse, locals: l
    end

    get '/browse/:year/:month' do |year, month|
      year = year.to_i
      month = month.to_i

      date = Date.new(year, month, 1)

      prepare_calendar(date)

      entries = []

      begin
        begin
          entries << @cal.day(date)
        rescue RangeError
          if month >= 11
            prepare_calendar(date)
            retry
          end
        end

        date = date.succ
      end until date.month != month

      render :month, locals: {year: year, month: month, entries: entries}
    end

    get '/api-doc' do
      render :apidoc
    end



    def ordinal(i)
      suff = {1 => 'st', 2 => 'nd', 3 => 'rd'}
      "#{i}#{suff[i] || 'th'}"
    end

    def format_weekday(i)
      %w{Sun Mon Tue Wed Thu Fri Sat}[i]
    end

    def format_season(s)
      ss = s.to_s
      ss[0].upcase + ss[1..-1]
    end

    def celebration_text(day, celeb)
      unless celeb.title.empty?
        r = celeb.rank.short_desc
        return "#{celeb.title}#{', ' if r}#{r}"
      end

      return "#{format_weekday day.weekday}, #{ordinal day.season_week} week of #{format_season day.season}"
    end

    def prepare_calendar(date)
      repo = ChurchCalendar.sanctorale_repository
      cal = 'default'
      factory = repo.get_calendar_factory cal
      @cal = factory.for_day date
    end
  end
end
