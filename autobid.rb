require 'bigdecimal'

class AutoBidService
  def initialize
  end

  # scenario 1
  # winner should be offer two with price 29 and first offer should remain at 30
  def scenario_one
    @offers = [
        {id: 1, price: 50, min_price: 30, delivery_quantity: 7000, status: "inside_contigent"},
        {id: 2, price: 50, min_price: 3, delivery_quantity: 5000, status: "inside_contigent"}
        ]
    @step = 1
    @capacity = 10000
    @start_price = 50.0
    @current_offer_id = 2
    @current_offer = @offers.find{ |o| o[:id] == @current_offer_id}
  end

  # scenario 2
  # winner should be offer 1 with price 25
  def scenario_two  
    @offers = [
        {id: 1, price: 50, min_price: 25, delivery_quantity: 7000, status: "inside_contigent"},
        {id: 2, price: 50, min_price: 26, delivery_quantity: 15000, status: "inside_contigent"}
        ]
    @step = 1
    @capacity = 10000
    @start_price = 50.0
    @current_offer_id = 2
    @current_offer = @offers.find{ |o| o[:id] == @current_offer_id}
  end

  # scenario 3
  # there should be two winner offers with price 26, and third one is no longer inside contigent because of capacity overdue
  def scenario_three
    @offers = [
        {id: 1, price: 50, min_price: 25, delivery_quantity: 4000, status: "inside_contigent"},
        {id: 2, price: 50, min_price: 26, delivery_quantity: 4000, status: "inside_contigent"},
        {id: 3, price: 50, min_price: 27, delivery_quantity: 4000, status: "inside_contigent"}
        ]
    @step = 1
    @capacity = 10000
    @start_price = 50.0
    @current_offer_id = 3
    @current_offer = @offers.find{ |o| o[:id] == @current_offer_id}
  end

  # scenario four
  # offers 1,2,4 should be inside contigent with price 27
  def scenario_four
    @offers = [
        {id: 1, price: 50, min_price: 25, delivery_quantity: 4000, status: "inside_contigent"},
        {id: 2, price: 50, min_price: 26, delivery_quantity: 4000, status: "inside_contigent"},
        {id: 3, price: 50, min_price: 27, delivery_quantity: 4000, status: "inside_contigent"},
        {id: 4, price: 50, min_price: 13, delivery_quantity: 1900, status: "inside_contigent"}
        ]
    @step = 1
    @capacity = 10000
    @start_price = 50.0
    @current_offer_id = 4
    @current_offer = @offers.find{ |o| o[:id] == @current_offer_id}
  end

  def print
    @offers.sort_by{|o| o[:status]}.each do |o|
      p "id: #{o[:id]}, price: #{o[:price].to_s}, min_price: #{o[:min_price]}, delivery_quantity: #{o[:delivery_quantity]}, status: #{o[:status]}" 
    end
  end

  def check_capacity
    @offered_capacity = @offers.select{|o| o[:id] != @current_offer[:id] && o[:status] == "inside_contigent"}.map{|o| o[:delivery_quantity]}.sum
  end

  def get_lowest_offer
    @lowest_offer = @offers.select{|o| o[:id] != @current_offer[:id]}.sort_by{|o| o[:min_price]}.first
  end

  def calculate_prices
    # is capacity_fullfilled?
    capacity_left = @capacity - @offered_capacity
    # if capacity_left == 0 everyone should be outside, according to 
    if capacity_left == 0
      p "I should be outside contigent"
    # if there is a chance to win we should compeet
    else
      if @lowest_offer[:min_price] == @current_offer[:min_price]
      elsif @lowest_offer[:min_price] < @current_offer[:min_price]
        until @current_offer[:price] == @current_offer[:min_price]
          @current_offer[:price] -= @step
        end
      elsif  @current_offer[:min_price] < @lowest_offer[:min_price]
        until @current_offer[:price] < @lowest_offer[:min_price] || @current_offer[:price] == @current_offer[:min_price]
          @current_offer[:price] -= @step
        end
      end
    end
  end

  def how_low_can_you_go
    # now let's take a look of qantity left_to_fulfill
    get_lowest_offer
    new_qty = @lowest_offer[:delivery_quantity]
    @next_offers = @offers.select{|o| o[:id] != @current_offer[:id] && o[:status] == "inside_contigent"}
    @next_offers.each do |offer|
      #find_me_min_value_to_work_with
      if offer[:min_price] > @current_offer[:price]
        until offer[:price] <= @current_offer[:min_price] || offer[:price] == offer[:min_price]
          offer[:price] -= @step
        end
        if (new_qty + offer[:delivery_quantity]) > @capacity
          offer[:status] = "outside_contigent"
          new_qty -= offer[:delivery_quantity]
        elsif (new_qty + offer[:delivery_quantity]) <= @capacity
          offer[:status] = "inside_contigent"
          new_qty += offer[:delivery_quantity]
        end
      elsif offer[:min_price] < @current_offer[:price]
        until offer[:price] < @current_offer[:min_price]
          offer[:price] -= @step
          offer[:status] = "inside_contigent"
          @current_offer[:status] = "outside_contigent"
        end
      end 
    end
  end

  def raise_me_up
    max_inside_contigent = @offers.select{|o| o[:status] == "inside_contigent"}.sort_by{|o| -o[:price]}.first
    @offers.select{|o| o[:status] == "inside_contigent" && o[:id] != max_inside_contigent[:id]}.each do |o|
      until o[:price] == max_inside_contigent[:price]
        o[:price] += @step
      end
    end
  end
end



@s = AutoBidService.new

#@s.scenario_one

#@s.scenario_two

#@s.scenario_three

@s.scenario_four

@s.check_capacity
@s.get_lowest_offer
@s.calculate_prices
@s.how_low_can_you_go
@s.raise_me_up

@s.print


