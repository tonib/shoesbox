
/** Handler for volume changes. */
VolumeControl = function() {
  var that = this;
  this.$slider = $('#volumeControl')
    .slider({
      formatter: function(value) { return value + ' %'; }
    })
    .on('slideStop', function() {
      that.onVolumeChange();
    })
    .data('slider');
}

VolumeControl.prototype.onVolumeChange = function() {
  var url = $('#music_cmd_player_path').val() + '?cmd=change_volume&volume=' +
    this.$slider.getValue();
  $.getScript(url);
};

VolumeControl.prototype.setVolume = function(newValue) {
  this.$slider.setValue(newValue);
};

VolumeControl.prototype.unbind = function() {
  this.$slider.destroy();
};
