require 'bigdecimal'
require 'date'
require 'active_support/time'

class AutoBidService
  def initialize
  end

  #based by my talk with Philippe
  # we have scenario
  # Reverse Auction with capacity 10.000, start price 10.00 and step 1
  # User 1 creates offer 1 with qty 4.000 and min_price: 


  # until capacity is fullfiled put everything inside contigent with start_price
  # once capacity is fullfiled we need to autobid
  # First check is there any offer that will match qty and check lowest price
  # when you check that if lower price until <=
  # When someone else creates new offer with qty that will fit inside auction capacity
  # we need to set price in order to get offers with status 'inside contigent', 
  # get their current_price (minimum) and reduce offer price by one step
  # When someone else creates new offer with qty that will exceed capacity
  # we need to fight against all offers that have status 'inside contigent',
  # and where min price is greater or equal to current offer



  # scenario 1
  # winner should be offer two with price 29 and first offer should remain at 30
  # PASS
  def scenario_one
    @offers = [
        {id: 1, price: 50, min_price: 30, delivery_quantity: 7000, status: "inside_contigent", user_updated_at: DateTime.now},
        {id: 2, price: 50, min_price: 3, delivery_quantity: 5000, status: "outside_contigent", user_updated_at: (DateTime.now + 3.minutes)}
        ]
    @step = 1
    @capacity = 10000
    @start_price = 50.0
    @current_offer_id = 2
    @current_offer = @offers.find{ |o| o[:id] == @current_offer_id}
  end

  # scenario 2
  # winner should be offer 1 with price 25
  # PASS
  def scenario_two  
    @offers = [
        {id: 1, price: 50, min_price: 25, delivery_quantity: 7000, status: "inside_contigent", user_updated_at: DateTime.now},
        {id: 2, price: 50, min_price: 26, delivery_quantity: 8000, status: "outside_contigent", user_updated_at: (DateTime.now + 5.minutes)}
        ]
    @step = 1
    @capacity = 10000
    @start_price = 50.0
    @current_offer_id = 2
    @current_offer = @offers.find{ |o| o[:id] == @current_offer_id}
  end

  # scenario 3
  # offer 1,2 are winners with price 9, offer 3 has price 9 but it's outside contigent
  # PASS
  def scenario_three
    @offers = [
        {id: 1, price: 10, min_price: 4, delivery_quantity: 4000, status: "inside_contigent", user_updated_at: DateTime.now},
        {id: 2, price: 10, min_price: 6, delivery_quantity: 4000, status: "inside_contigent", user_updated_at: (DateTime.now + 3.minutes)},
        {id: 3, price: 10, min_price: 9, delivery_quantity: 4000, status: "outside_contigent", user_updated_at: (DateTime.now + 5.minutes)}
        ]
    @step = 1
    @capacity = 10000
    @start_price = 50.0
    @current_offer_id = 3
    @current_offer = @offers.find{ |o| o[:id] == @current_offer_id}
  end

  # scenario four
  # offers 1,2 are winners with price 9, 
  # offer 4 has price 8 (also winner), 
  # and offer 3 has price 9 (outside_contigent)
  #
  def scenario_four
    @offers = [
        {id: 1, price: 9, min_price: 4, delivery_quantity: 4000, status: "inside_contigent", user_updated_at: DateTime.now},
        {id: 2, price: 9, min_price: 6, delivery_quantity: 4000, status: "inside_contigent", user_updated_at: (DateTime.now + 3.minutes)},
        {id: 3, price: 9, min_price: 9, delivery_quantity: 4000, status: "outside_contigent", user_updated_at: (DateTime.now + 5.minutes)},
        {id: 4, price: 9, min_price: 3, delivery_quantity: 1950, status: "outside_contigent", user_updated_at: (DateTime.now + 7.minutes)}
        ]
    @step = 1
    @capacity = 10000
    @start_price = 50.0
    @current_offer_id = 4
    @current_offer = @offers.find{ |o| o[:id] == @current_offer_id}
  end

  # scenario five
  # offer 4,5 have price 8 and they are winners along with
  # offers 1,2 with price 9
  # offer 3 has lost with price 9
  def scenario_five
    @offers = [
        {id: 1, price: 9, min_price: 4, delivery_quantity: 4000, status: "inside_contigent", user_updated_at: DateTime.now},
        {id: 2, price: 9, min_price: 6, delivery_quantity: 4000, status: "inside_contigent", user_updated_at: (DateTime.now + 3.minutes)},
        {id: 3, price: 9, min_price: 9, delivery_quantity: 4000, status: "outside_contigent", user_updated_at: (DateTime.now + 5.minutes)},
        {id: 4, price: 8, min_price: 3, delivery_quantity: 1950, status: "inside_contigent", user_updated_at: (DateTime.now + 7.minutes)},
        {id: 5, price: 8, min_price: 2, delivery_quantity: 50, status: "outside_contigent", user_updated_at: (DateTime.now + 8.minutes)}
        ]
    @step = 1
    @capacity = 10000
    @start_price = 50.0
    @current_offer_id = 5
    @current_offer = @offers.find{ |o| o[:id] == @current_offer_id}
  end

  # winners
  #   offer 6 qty: 2000, Price 5 , min_price: 5
  #   offer 4 qty: 1950, price: 5, min_price: 3,  
  #   offer 5 qty: 50, price: 5, min_price: 2,  
  #   offer 1 qty: 4000, price: 6, min_price: 4,  
  # losers
  #   offer 2 qty: 4000, price: 6, min_price: 6,  
  #   offer 3 qty: 4000, price: 9, min_price: 9,
  def scenario_six
    @offers = [
        {id: 1, price: 9, min_price: 4, delivery_quantity: 4000, status: "inside_contigent", user_updated_at: DateTime.now},
        {id: 2, price: 9, min_price: 6, delivery_quantity: 4000, status: "inside_contigent", user_updated_at: (DateTime.now + 3.minutes)},
        {id: 3, price: 9, min_price: 9, delivery_quantity: 4000, status: "outside_contigent", user_updated_at: (DateTime.now + 5.minutes)},
        {id: 4, price: 8, min_price: 3, delivery_quantity: 1950, status: "inside_contigent", user_updated_at: (DateTime.now + 7.minutes)},
        {id: 5, price: 8, min_price: 2, delivery_quantity: 50, status: "inside_contigent", user_updated_at: (DateTime.now + 8.minutes)},
        {id: 6, price: 8, min_price: 5, delivery_quantity: 2000, status: "outside_contigent", user_updated_at: (DateTime.now + 9.minutes)}
        ]
    @step = 1
    @capacity = 10000
    @start_price = 50.0
    @current_offer_id = 6
    @current_offer = @offers.find{ |o| o[:id] == @current_offer_id}
  end

  def print
    @offers.sort_by{|o| o[:price]}.sort_by{|o| o[:delivery_quantity]}.sort_by{|o| o[:user_updated_at]}.sort_by{|o| o[:status]}.each do |o|
      p "id: #{o[:id]}, price: #{o[:price].to_s}, min_price: #{o[:min_price]}, delivery_quantity: #{o[:delivery_quantity]}, status: #{o[:status]}, user_updated_at: #{o[:user_updated_at].strftime("%-d.%-m.%Y %-l:%M%p")}"  
    end
  end
  
  def autobid
    # 1. uzmeš sve ponude osim najbolje (kriterij min_price)
    best_offer = @offers.sort_by{|o| o[:min_price]}.first
    # 2. svaku od tih ponuda smanji za step
    @offers.select{|o| o[:id] != best_offer[:id]}.each do |o|
      o[:price] -= @step
    end
    # 3. ako je nova cijena iznad minimalne onda je ponudi (is_offer_competable)
    # i postavi neki flag da je napravljena ponuda    
  end

  def is_offer_competable(offer_price, best_offer_price)
    offer_price >= best_offer_price
  end

  def ranking
    @offers = @offers.sort_by{|o| o[:price]}.sort_by{|o| o[:delivery_quantity]}.sort_by{|o| o[:user_updated_at]}
    kwh_sum = 0
    inside_contingent = []
    outside_contingent = []

    @offers.each do |o|
      kwh_sum += o[:delivery_quantity]
      is_inside_contingent = kwh_sum <= @capacity
      
      if is_inside_contingent
        o[:status] = "inside_contigent"
      else
        o[:status] = "outside_contigent"
      end
    end
  end
end



@s = AutoBidService.new

@s.scenario_one

#@s.scenario_two

#@s.scenario_three

#@s.scenario_four

#@s.scenario_five

#@s.scenario_six

@s.autobid
@s.ranking



@s.print


