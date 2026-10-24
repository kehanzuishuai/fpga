"""Prepare plot coverage in an existing descriptor stage before color selection."""
def pipeline_plot_flags(s):
    marker=' pixel_info spectrum_ready,waveform_ready;'
    assert marker in s
    s=s.replace(marker,''' pixel_info mask_source,plot_ready;
 assign mask_source=info_pipe[6];
 wire waveform_area=mask_source.wave_initialized && mask_source.x>=80 && mask_source.x<704 && mask_source.y>=208 && mask_source.y<=436;
 wire phase_area=mask_source.xy_signal && mask_source.x>=1572 && mask_source.x<1828 && mask_source.y>=198 && mask_source.y<454;
 always @* begin
  plot_ready=mask_source;
  plot_ready.plot_flags[0]=waveform_area && {1'b0,mask_source.y}+13'd3>={1'b0,mask_source.wave_min} && {1'b0,mask_source.y}<={1'b0,mask_source.wave_max}+13'd3;
  plot_ready.plot_flags[1]=waveform_area && {1'b0,mask_source.y}+13'd1>={1'b0,mask_source.wave_min} && {1'b0,mask_source.y}<={1'b0,mask_source.wave_max}+13'd1;
  plot_ready.plot_flags[2]=waveform_area && mask_source.y>=mask_source.wave_min && mask_source.y<=mask_source.wave_max;
  plot_ready.plot_flags[3]=phase_area && ((mask_source.phase_left && mask_source.x>1572) || mask_source.phase_vertical);
  plot_ready.plot_flags[4]=phase_area && mask_source.phase_aligned;
 end
'''+marker)
    s=s.replace('else info_pipe[delay_pixel]<=info_pipe[delay_pixel-1];', 'else if(delay_pixel==7)info_pipe[delay_pixel]<=plot_ready;else info_pipe[delay_pixel]<=info_pipe[delay_pixel-1];')
    a=s.index('   if(aligned.wave_initialized &&');b=s.index('   if(aligned.status_live && aligned.status_data[5]',a)
    s=s[:a]+'''   if(aligned.plot_flags[0])begin base_red<=scene_color[23:16]+8'd12;base_green<=scene_color[15:8]+8'd23;base_blue<=scene_color[7:0]+8'd23;end
   if(aligned.plot_flags[1])begin base_red<=143;base_green<=210;base_blue<=216;end
   if(aligned.plot_flags[2])begin base_red<=211;base_green<=253;base_blue<=246;end
'''+s[b:]
    a=s.index('   if(aligned.xy_signal &&');b=s.index('   if(aligned.initialized &&',a)
    s=s[:a]+'''   if(aligned.plot_flags[3])begin base_red<=132;base_green<=208;base_blue<=223;end
   if(aligned.plot_flags[4])begin base_red<=175;base_green<=231;base_blue<=240;end
'''+s[b:]
    return s
