module Econ
	R = PennJSON::Remote

	def self.admin_report
		balance_wallets = 0 # Total balance for all non-admin wallets
		balance_banks = 0 # Total balance for all accounts
		balance_banks_mortal = 0 # Balance for non-admin accounts
		jobs_total_payout = 0 # Total payout for cargo jobs
		jobs_players = [] # Array of players who claimed jobs
		wallets = [] # Array of player wallets
		accounts = [] # Array of non-admin accounts
		wealth = {} # Hash where Key == Player and Value == Total credits

		jobs = CargoJob.where(:completed => true, :created_at.gt => DateTime.now - 30.days)

		Wallet.all.each do |wallet|
			unless R.orflags(wallet.id, "Wr").to_bool || !R.hastype(wallet.id, "player").to_bool
				wallets << wallet
				balance_wallets += wallet.balance
				wealth[wallet.id] = wallet.balance
			end
		end

		Account.where(open: true).each do |account|
			balance_banks += account.balance
			unless R.orflags(account.owner, "Wr").to_bool || !R.hastype(account.owner, "player").to_bool
				accounts << account
				balance_banks_mortal += account.balance
				wealth[account.owner] += account.balance
			end
		end

		jobs.each do |job| 
			jobs_total_payout += job.price
			jobs_players << job.claimed_by
		end

		wealth_sorted = wealth.to_a.sort { |i, j| i.last <=> j.last }.reverse
		player_wealth_percent = (balance_wallets + balance_banks_mortal) / (balance_wallets + balance_banks)

		ret = titlebar("Economy Report") + "\n"
		ret << credit_format(balance_wallets + balance_banks).bold.yellow + " credits across all wallets and accounts." + "\n"
		ret << "\t" + credit_format(balance_wallets + balance_banks_mortal).yellow + " of that or #{(player_wealth_percent * 100).to_i.to_s.yellow}% is held by #{wealth.count} players." + "\n"
		ret << "\t\t" + credit_format(balance_wallets).yellow + " credits in player wallets." + "\n"
		ret << "\t\t" + credit_format(balance_banks_mortal).yellow + " credits in player bank accounts." + "\n\n"
		ret << "The top 10 wealthiest players have #{credit_format(top10 = wealth_sorted.take(10).collect { |i| i.last}.inject { |i, j| i += j}).yellow} credits." + "\n"
		ret << "\t" + "That's #{(top10 / (balance_wallets + balance_banks_mortal) * 100).to_i.to_s.yellow}% of all player wealth." + "\n"
		ret << middlebar("Last 30 Days") + "\n"
		ret << jobs.count.to_s.bold.yellow + " cargo jobs completed for a total of " + credit_format(jobs_total_payout).yellow + " credits." + "\n"
		ret << "\t" + jobs_players.uniq.count.to_s.yellow + " different players completed jobs." + "\n"
		ret << footerbar
	end
end