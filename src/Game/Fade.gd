extends ColorRect

func fade_in(d, callback):
	var duration = 2.0
	$Tween.interpolate_property(self, 'color:a', color.a, 0.0, duration, Tween.TRANS_QUART, Tween.EASE_OUT)
	$Tween.interpolate_callback(callback[0], duration*d, callback[1])
	$Tween.start()

func fade_out(d, callback):
	color = Color(0,0,0,0)
	var duration = 1.0
	$Tween.interpolate_property(self, 'color:a', 0.0, 1.0, duration, Tween.TRANS_QUART, Tween.EASE_OUT)
	$Tween.interpolate_callback(callback[0], duration*d, callback[1])
	$Tween.start() 