class Defect
  #include MongoMapper::Document

  #key :defect_id, String
  #key :manufacture_date, String
  #key :manufacture_time, Time
  #key :product, Product
  #key :plant, Plant
  #key :operator, String
  #key :outcome, String
  #key :cost, Float
  #key :root_cause, String

  def self.collection
    Cubicle.mongo.database["defects"]
  end

  def self.create(attributes)
    self.collection.insert(attributes)
  end

  def self.create_test_data
    Defect.create :defect_id=>"1",
                  :manufacture_date=>"2010-01-01",
                  :manufacture_time=>"2010-01-01".to_time,
                  :product=>{:name=>"Sad Day Moonshine",:category=>"Alcohol"},
                  :plant=>{:name=>"Plant1",:address=>{:region=>"West",:location=>"San Francisco, Ca"}},
                  :operator=>"Franny",
                  :outcome=>"Repaired",
                  :cost=>0.78,
                  :root_cause=>:act_of_god

    Defect.create :defect_id=>"2",
                  :manufacture_date=>"2010-01-05",
                  :manufacture_time=>"2010-01-05".to_time,
                  :product=>{:name=>"Evil's Pickling Spice",:category=>"Baking"},
                  :plant=>{:name=>"Plant2",:address=>{:region=>"Midwest",:location=>"Des Moines, Ia"}},
                  :operator=>"Seymour",
                  :outcome=>"Discarded",
                  :cost=>0.02,
                  :root_cause=>:operator_error

    Defect.create :defect_id=>"3",
                  :manufacture_date=>"2010-02-01",
                  :manufacture_time=>"2010-02-01".to_time,
                  :product=>{:name=>"Sad Day Moonshine",:category=>"Alcohol"},
                  :plant=>{:name=>"Plant1",:address=>{:region=>"West",:location=>"San Francisco, Ca"}},
                  :operator=>"Zooey",
                  :outcome=>"Consumed",
                  :cost=>2.94,
                  :root_cause=>:poor_judgment

    Defect.create :defect_id=>"4",
                  :manufacture_date=>"2009-12-09",
                  :manufacture_time=>"2009-12-09".to_time,
                  :product=>{:name=>"Brush Fire Bottle Rockets",:category=>"Fireworks"},
                  :plant=>{:name=>"Plant19",:address=>{:region=>"South",:location=>"Burmingham, Al"}},
                  :operator=>"Buddy",
                  :outcome=>"Repaired",
                  :cost=>0.43,
                  :root_cause=>:act_of_god

    Defect.create :defect_id=>"5",
                  :manufacture_date=>"2010-01-01",
                  :manufacture_time=>"2010-01-01".to_time,
                  :product=>{:name=>"Sad Day Moonshine",:category=>"Alcohol"},
                  :plant=>{:name=>"Plant3",:address=>{:region=>"West",:location=>"Oakland, Ca"}},
                  :operator=>"Franny",
                  :outcome=>"Repaired",
                  :cost=>12.19,
                  :root_cause=>:defective_materials
  end
end