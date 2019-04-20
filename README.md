# Slytherin
Slythern is easy to use seeder which was wriited by ruby language  
you only write a byte yml file  
Slytherin can use within seed.rb which Rails has

# Example
following code, as an example for slytherin code  
to make "prefecture"  

prefecture.yml
```
Mouse:  
  Prefecture:
    loop: 10
    col_info:
      name:
        init_data: ["Hokkaido", "Aomori"]
```  

following code, as an example for call slytherin in seed.rb 

seed.rb

```
Slytherin.do_seed './db/slytherin/mouse/prefecture.yml'
```  

if you want to more details, get information from Slytherin/test/slytherin_test.rb  
and understand its' code  


## Installation
Add this line to your application's Gemfile:

```ruby
gem 'slytherin', git: "https://github.com/SlytherinGem/Slytherin"
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install slytherin
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
