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

get '/employee_show' do
  @employee = Employee.find(params["id"])
  if @employee
    erb :employee_show
  else
    erb :no_employee_found
  end
end

get '/new' do
  @employee = Employee.new

  erb :employees_new
end

get '/employees_new' do
  @employee = Employee.create(params)
  if @employee.valid?
    redirect('/')
  else
    p @employee.errors.messages
    erb :employees_new
  end
end

get '/searched' do
  search = params["search"]

  @employees = Employee.where("name like ? or github = ? or slack = ?", "%#{search}%", search, search)
  erb :searched
end

get '/edit' do
  id = params["id"]
  database = PG.connect(dbname: "tiy-database")
  employees = database.exec("select * from employees where id =$1", [id])

  @employee = employees.first

  erb :edit

end

get '/update' do

  id = params["id"]
  name = params["name"]
  phone = params["phone"]
  address = params["address"]
  position = params["position"]
  salary = params["salary"]
  github = params["github"]
  slack = params["slack"]
  database = PG.connect(dbname: "tiy-database")
  database.exec("UPDATE employees SET name = $1, phone = $2, address = $3, position = $4, salary = $5, github = $6, slack =$7 WHERE id = $8;", [name, phone, address, position, salary, github, slack, id])

  employees = database.exec("select * from employees where id =$1", [id])
  @employee = employees.first
  erb :employee_show
end

get '/delete' do
  id = params["id"]
  database = PG.connect(dbname: "tiy-database")
  database.exec("DELETE FROM  employees where id = $1", [id])

  redirect('/employees')
end
