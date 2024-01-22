require "pg"

class DatabasePersistance
  def initialize(logger)
    @db = PG.connect(dbname: "todos")
    # @logger = logger
    setup_tables
  end

  def all_lists
    sql = <<~SQL
            SELECT lists.*,
                   COUNT(todos.id) AS todos_total,
                   COUNT(NULLIF(todos.completed,true)) AS todos_not_done
            FROM lists
            LEFT JOIN todos
              ON lists.id = todos.list_id
            GROUP BY lists.id
            ORDER BY lists.name;
          SQL
    result = query(sql)

    result.map do |list_tuple|
      { id: list_tuple["id"].to_i, name: list_tuple["name"],
        todos_not_done: list_tuple["todos_not_done"].to_i,
        todos_total: list_tuple["todos_total"].to_i }
    end
  end

  def find_list(id)
    every_list = all_lists
    selected_list =
      every_list.select { |list| list[:id] == id}.first
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1)"
    query(sql, list_name)
  end

  def update_list_name(id, list_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2"
    query(sql, list_name, id)
  end

  def delete_list(id)
    query("DELETE FROM todos WHERE list_id = $1", id)
    query("DELETE FROM lists WHERE id = $1", id)
  end

  def create_new_todo(list_id, todo_name)
    sql = "INSERT INTO todos (name, list_id) VALUES ($1, $2)"
    query(sql, todo_name, list_id)
  end

  def get_todo_name(list_id, todo_id)
    sql = "SELECT * FROM todos WHERE list_id = $1 AND id = $2"
    result = query(sql, list_id, todo_id)

    result.map do |todo|
      { name: todo["name"] }
    end
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = "DELETE FROM todos WHERE list_id = $1 AND id = $2"
    query(sql, list_id, todo_id)
  end

  def update_todo_status(list_id, todo_id)
    sql = "UPDATE todos SET completed = NOT completed WHERE list_id = $1 AND id = $2"
    query(sql, list_id, todo_id)
  end

  def mark_all_todos_as_completed(list_id)
    sql = "UPDATE todos SET completed = true WHERE list_id = $1"
    query(sql, list_id)
  end

  def get_list_todo_names(id)
    todo_sql = "SELECT * FROM todos WHERE list_id = $1"
    todo_result = query(todo_sql, id)

    todo_result.map do |todo_tuple|
      { name: todo_tuple["name"] }
    end
  end

  def todo_tuples(id)
    todo_sql = "SELECT * FROM todos WHERE list_id = $1"
    todo_result = query(todo_sql, id)

    todo_result.map do |todo_tuple|
      { id: todo_tuple["id"],
        name: todo_tuple["name"],
        completed: todo_tuple["completed"] == "t" }
    end
  end

  private

  def query(sql, *params)
    # @logger.info "#{sql}: #{params}"
    @db.exec_params(sql, params)
  end

  def setup_tables
    sql = <<~SQL
      CREATE TABLE IF NOT EXISTS lists (
        id serial PRIMARY KEY,
        name text NOT NULL UNIQUE
      );

      CREATE TABLE IF NOT EXISTS todos (
        id serial PRIMARY KEY,
        name text NOT NULL,
        list_id int NOT NULL REFERENCES lists(id),
        completed boolean DEFAULT false
      );
    SQL

    @db.exec(sql)
  end
end