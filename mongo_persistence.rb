require "mongo"

class MongoPersistence
  def initialize(logger)
    uri = "mongodb://127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+2.1.1"
    client = Mongo::Client.new(uri, database: 'todo_trash')

    @db = client[:todos]
    # @logger = logger
  end

  def add_item(name)
    @db.insert_one(name)
  end

  def add_items(names)
    if names.size == 1
      @db.insert_one(names[0])
    elsif names.size > 1
      @db.insert_many(names)
    end
  end

  def all_items
    all_items = []

    @db.find({}).limit(5).each do |document|
      all_items.push(document["name"])
    end

    all_items.join(', ')
  end
end