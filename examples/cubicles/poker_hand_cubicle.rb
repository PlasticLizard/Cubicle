class PokerHandCubicle
  extend Cubicle

  date       :date,  :field_name=>'match_date'
  dimension  :month, :expression=>'this.match_date.substring(0,7)'
  dimension  :year,  :expression=>'this.match_date.substring(0,4)'

  dimensions :table, :winner, :winning_hand

  count :total_hands,            :expression=>'true'
  count :total_draws,            :expression=>'this.winning_hand=="draw"'
  sum   :total_winnings,         :field_name=>'amount_won'
  avg   :avg_winnings,           :field_name=>'amount_won'

  ratio :royal_flush_pct,        :royal_flushes, :total_hands
end