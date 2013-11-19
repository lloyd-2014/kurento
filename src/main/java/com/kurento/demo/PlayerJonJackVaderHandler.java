/*
 * (C) Copyright 2013 Kurento (http://kurento.org/)
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the GNU Lesser General Public License
 * (LGPL) version 2.1 which accompanies this distribution, and is available at
 * http://www.gnu.org/licenses/lgpl-2.1.html
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 */
package com.kurento.demo;

import com.kurento.kmf.content.HttpPlayerHandler;
import com.kurento.kmf.content.HttpPlayerService;
import com.kurento.kmf.content.HttpPlayerSession;
import com.kurento.kmf.media.JackVaderFilter;
import com.kurento.kmf.media.MediaPipeline;
import com.kurento.kmf.media.MediaPipelineFactory;
import com.kurento.kmf.media.PlayerEndPoint;

@HttpPlayerService(name = "PlayerJonJackVaderHandler", path = "/playerJsonJack", useControlProtocol = true)
public class PlayerJonJackVaderHandler extends HttpPlayerHandler {

	@Override
	public void onContentRequest(HttpPlayerSession session) throws Exception {
		getLogger().info("Received request to " + session.getContentId());
		getLogger().info("Recovering MediaPipelineFactory");
		MediaPipelineFactory mpf = session.getMediaPipelineFactory();
		getLogger().info("Creating MediaPipeline");
		MediaPipeline mp = mpf.create();
		session.releaseOnTerminate(mp);
		getLogger().info("Creating PlayerEndPoint");
		PlayerEndPoint playerEndPoint = mp
				.createPlayerEndPoint("file:///opt/video/fiwarecut.webm");
		getLogger().info("Creating JackVaderFilter");
		JackVaderFilter filter = mp.createJackVaderFilter();
		getLogger().info("Connecting " + playerEndPoint + " to " + filter);
		playerEndPoint.connect(filter);
		session.setAttribute("player", playerEndPoint);
		session.start(filter);
	}

	@Override
	public void onContentStarted(HttpPlayerSession session) {
		PlayerEndPoint playerendPoint = (PlayerEndPoint) session
				.getAttribute("player");
		getLogger().info("Invoking play on " + playerendPoint);
		playerendPoint.play();
	}

}
