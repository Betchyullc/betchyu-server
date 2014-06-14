# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
bets=Bet.create([
  {verb: "Lose", amount: 5.1, noun: "pounds", duration: 10, owner: "100006865445598", initial: 199.0, stakeType: "Amazon Gift Card", stakeAmount: 15, status: "pending"},
  {verb: "Stop", amount: 0.0, noun: "Smoking", duration: 10, owner: "100006865445598", initial: 0.0, stakeType: "Amazon Gift Card", stakeAmount: 15, status: "pending"},
  {verb: "Workout", amount: 5.0, noun: "times", duration: 5, owner: "100006865445598", initial: 0.0, stakeType: "Amazon Gift Card", stakeAmount: 15, status: "pending"},
  {verb: "Run", amount: 5.1, noun: "miles", duration: 10, owner: "100006865445598", initial: 1.0, stakeType: "Amazon Gift Card", stakeAmount: 15, status: "pending"}
])

Invite.create(status: "open", invitee: "100006865445598", inviter: "100006865445598", bet:bets.first)
Invite.create(status: "rejected", invitee: "100006865445598", inviter: "100006865445598",bet:bets.second)

Transaction.create(braintree_id: "2p54xw", user: "100006865445598", submitted: false)

Update.create(value: 3.2, bet_id: 4)
Update.create(value: 1.0, bet_id: 2)
Update.create(value: 1.0, bet_id: 2)
