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
  #key :account_id=>String

  def self.collection
    Cubicle.mongo.database["defects"]
  end

  def self.create(attributes)
    self.collection.insert(attributes,{})
  end

  def self.create_duration_test_data
    time = "1/1/2000".to_time
    t1,t2,t3,t4 = time,time.advance(:days=>1),time.advance(:days=>3),time.advance(:days=>22)
    Defect.create :defect_id=>"1",
                  :manufacture_date=>"2010-01-01",
                  :manufacture_time=>"2010-01-01".to_time,
                  :product=>{:name=>"Sad Day Moonshine",:category=>"Alcohol"},
                  :plant=>{:name=>"Plant1",:address=>{:region=>"West",:location=>"San Francisco, Ca"}},
                  :operator=>"a",
                  :outcome=>"Repaired",
                  :cost=>0.78,
                  :root_cause=>:act_of_god,
                  :ms1=>t1,
                  :ms2=>t2,
                  :ms3=>t3,
                  :ms4=>t4,
                  :account_id=>"a1"
    t1,t2,t3,t4 = time, time.advance(:days=>2),time.advance(:days=>4),time.advance(:days=>28)
    Defect.create :defect_id=>"2",
                  :manufacture_date=>"2010-01-01",
                  :manufacture_time=>"2010-01-01".to_time,
                  :product=>{:name=>"Sad Day Moonshine",:category=>"Alcohol"},
                  :plant=>{:name=>"Plant1",:address=>{:region=>"West",:location=>"San Francisco, Ca"}},
                  :operator=>"b",
                  :outcome=>"Repaired",
                  :cost=>0.78,
                  :root_cause=>:act_of_god,
                  :ms1=>t1,
                  :ms2=>t2,
                  :ms3=>t3,
                  :ms4=>t4,
                  :account_id=>"a1"
  end

  def self.create_test_data

    Defect.create :defect_id=>"1",
                  :manufacture_date=>"2010-01-01",
                  :manufacture_time=>"2010-01-01".to_time,
                  :product=>{:name=>"Sad Day Moonshine",:category=>"Alcohol"},
                  :plant=>{:name=>"Plant1",:address=>{:region=>"West",:location=>"San Francisco, Ca"}},
                  :operator=>"Franny",
                  :outcome=>"Repaired",
                  :cost=>6.50,
                  :root_cause=>:act_of_god,
                  :account_id=>"a1",
                  :audits=>[{:auditor=>"Nina", :score=>1},{:auditor=>"Pinta", :score=>2}],
                  :hash_pipes=>{:defect=>{:vote=>"yes",:weight=>1},:metaphor=>{:vote=>"no",:weight=>2}}

    Defect.create :defect_id=>"2",
                  :manufacture_date=>"2010-01-05",
                  :manufacture_time=>"2010-01-05".to_time,
                  :product=>{:name=>"Evil's Pickling Spice",:category=>"Baking"},
                  :plant=>{:name=>"Plant2",:address=>{:region=>"Midwest",:location=>"Des Moines, Ia"}},
                  :operator=>"Seymour",
                  :outcome=>"Discarded",
                  :cost=>0.02,
                  :root_cause=>:operator_error ,
                  :account_id=>"a1",
                  :audits=>[{:auditor=>"Santa Maria", :score=>3},{:auditor=>"Nina",:score=>4}],
                  :hash_pipes=>{:must=>{:vote=>"no",:weight=>3},:die=>{:vote=>"yes",:weight=>1}}

    Defect.create :defect_id=>"3",
                  :manufacture_date=>"2010-02-01",
                  :manufacture_time=>"2010-02-01".to_time,
                  :product=>{:name=>"Sad Day Moonshine",:category=>"Alcohol"},
                  :plant=>{:name=>"Plant1",:address=>{:region=>"West",:location=>"San Francisco, Ca"}},
                  :operator=>"Zooey",
                  :outcome=>"Consumed",
                  :cost=>2.94,
                  :root_cause=>:poor_judgment,
                  :account_id=>"a1",
                  :audits=>[{:auditor=>"Pinta",:score=>5}],
                  :hash_pipes=>{:defect=>{:vote=>"no",:weight=>2}}

    Defect.create :defect_id=>"4",
                  :manufacture_date=>"2009-12-09",
                  :manufacture_time=>"2009-12-09".to_time,
                  :product=>{:name=>"Brush Fire Bottle Rockets",:category=>"Fireworks"},
                  :plant=>{:name=>"Plant19",:address=>{:region=>"South",:location=>"Burmingham, Al"}},
                  :operator=>"Buddy",
                  :outcome=>"Repaired",
                  :cost=>0.43,
                  :root_cause=>:act_of_god,
                  :account_id=>"a1",
                  :audits=>[{:auditor=>"Santa Maria",:score=>4}, {:auditor=>"Nina", :score=>3}],
                  :hash_pipes=>{}

    Defect.create :defect_id=>"5",
                  :manufacture_date=>"2010-01-01",
                  :manufacture_time=>"2010-01-01".to_time,
                  :product=>{:name=>"Sad Day Moonshine",:category=>"Alcohol"},
                  :plant=>{:name=>"Plant3",:address=>{:region=>"West",:location=>"Oakland, Ca"}},
                  :operator=>"Franny",
                  :outcome=>"Repaired",
                  :cost=>12.19,
                  :root_cause=>:defective_materials,
                  :account_id=>"a1",
                  :audits=>[]

    #Should be filtered out
    Defect.create :defect_id=>"6",
                  :manufacture_date=>"2009-12-09",
                  :manufacture_time=>"2009-12-09".to_time,
                  :product=>{:name=>"Brush Fire Bottle Rockets",:category=>"Fireworks"},
                  :plant=>{:name=>"Plant19",:address=>{:region=>"South",:location=>"Burmingham, Al"}},
                  :operator=>"Buddy",
                  :outcome=>"Repaired",
                  :cost=>10000,
                  :root_cause=>:act_of_god,
                  :account_id=>"a2"
  end
end