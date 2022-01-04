# This is essentially exactly the same as the implementation in StringDistances
# but without checking the q (length of qgrams) which is not meaningful on LempelZivDicts.
function (dist::AbstractQGramDistance)(qc1::LempelZivDict{G}, qc2::LempelZivDict{G}) where {G}
	d1, d2 = qc1.lzdict, qc2.lzdict
	c = eval_start(dist)
	for (s1, n1) in d1
		index = Base.ht_keyindex2!(d2, s1)
		if index <= 0
			c = eval_op(dist, c, n1, 0)
		else
			c = eval_op(dist, c, n1, d2.vals[index])
		end
	end
	for (s2, n2) in d2
		index = Base.ht_keyindex2!(d1, s2)
		if index <= 0
			c = eval_op(dist, c, 0, n2)
		end
	end
	eval_end(dist, c)
end