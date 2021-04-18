Clock.bpm = 110

p3 >> play("<( )( f--)>< ([nn]d)>").every(4, "stutter", dur=1/2, amp=0.5, pan=[-1, 1, 1], fmod=0.5, slide=2)

p1 >> play("  a ")

p2 >> prophet(P[[0, 2, 3, 2], 1, var([2, [5, 9]], [4, 8])] + P(var([1, -1], 32), 1), dur=var([8, 4], [32, 16]), amp=0.9, oct=4, spin=0, coarse=[0.1, 0, 0.2])

p4 >> sitar([-1, 1], amp=sinvar([0.6, 0.9], 16), dur=PDur(5, 12)*2, vib=0.1, lpf=1000).every(4, "stutter", 2, pan=[-1, 1])

p5 >> orient(p4.pitch, dur=[1/2, 1], amp=0.1, room=[0.5, 1], mix=0.3, blur=[0, 0], hpf=100).every(8 ,"reverse").stop()

p8 >> bug([[-1, 2], -2, (1, [3, [4, 8, 12], 1])], amp=0.6, dur=0, pan=sinvar([-0.2, 0.2], 8), tremolo=2).every(16, "stutter", fmod=Cycle([1, 2]), pan=[1, -1], dur=5, echo=[1, 2]).stop()

