require 'sinatra'
require 'pg'
require 'sinatra/reloader' if development?
require 'active_record'

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(
  adapter: "postgresql",
  database: "tiy-database"
)

class Employee < ActiveRecord::Base
  validates :name, presence: true
  validates :position, inclusion: { in: %w{Instructor Student}, message: "%{value} must be Instructor or Student" }
  validates :salary, presence: true

  self.primary_key = "id"
end

class Course < ActiveRecord::Base
  validates :name, presence: true

  self.primary_key = "id"
end

after do
  ActiveRecord::Base.connection.close
end

get '/' do
  erb :home
end

get '/employees' do
  @employees = Employee.all

  erb :employees
end

get '/courses' do
  @courses = Course.all

  erb :courses
end

get '/employee_show' do
  @employee = Employee.find(params["id"])
  if @employee
    erb :employee_show
  else
    redirect('/no_employee_found')
  end
end

get '/course_show' do
  @course = Course.find(params["id"])
  if @course
    erb :course_show
  else
    redirect('/')
  end
end

get '/new' do
  @employee = Employee.new

  erb :employees_new
end

get '/course_new' do
  @course = Employee.new

  erb :new_course
end

get '/employees_new' do
  @employee = Employee.create(params)
  if @employee.valid?
    redirect('/')
  else
    erb :employees_new
  end
end

get '/new_course' do
  @course = Course.create(params)
  if @course.valid?
    redirect('/')
  else
    erb :new_course
  end
end

get '/searched' do
  search = params["search"]

  @employees = Employee.where("name like ? or github = ? or slack = ?", "%#{search}%", search, search)
  erb :searched
end

get '/course_searched' do
  search = params["search"]

  @courses = Course.where("name like ?", "%#{search}%")
  erb :course_searched
end

get '/edit' do
  database = PG.connect(dbname: "tiy-database")

  @employee = Employee.find(params["id"])

  erb :edit

end

get '/course_edit' do
  database = PG.connect(dbname: "tiy-database")

  @course = Course.find(params["id"])

  erb :course_edit
end

get '/update' do
  database = PG.connect(dbname: "tiy-database")

  @employee = Employee.find(params["id"])

  @employee.update_attributes(params)

  if @employee.valid?
    redirect to("/employee_show?id=#{@employee.id}")
  else
    erb :edit
  end
end

get '/course_update' do
  database = PG.connect(dbname: "tiy-database")

  @course = Course.find(params["id"])

  @course.update_attributes(params)

  if @course.valid?
    redirect to("/course_show?id=#{@course.id}")
  else
    erb :edit
  end
end

get '/delete' do
  database = PG.connect(dbname: "tiy-database")

  @employee = Employee.find(params["id"])

  @employee.destroy

  redirect('/employees')
end

get '/course_delete' do
  database = PG.connect(dbname: "tiy-database")

  @course = Course.find(params["id"])

  @course.destroy

  redirect('/courses')
end

# Need to double the gets for courses. copy then include pertinant information.
