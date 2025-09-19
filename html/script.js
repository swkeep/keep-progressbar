if (!window.Vue) {
    const app = document.getElementById('#app');
    if (app) app.style.display = 'none';
    console.error('[keep-progreesbar] Failed to load vue from CDN');
} else {
    const { createApp, ref, onMounted, onBeforeUnmount } = Vue;

    createApp({
        setup() {
            const window_config = ref({
                label: 'Progress',
                icon: 'fa-solid fa-spinner',
                theme: 'default',
            });

            const stages = ref([]);
            const progress = ref(0);
            const current_stage_index = ref(0);
            const total_duration = ref(0);
            const can_cancel = ref(false);
            const remaining_time = ref(0);
            const is_active = ref(false);
            const locale = ref({});

            let interval_id = null;
            let stage_start_time = null;
            let remaining_interval_id = null;

            function update_remaining_time() {
                let elapsed = 0;
                for (let i = 0; i < current_stage_index.value; i++) {
                    elapsed += stages.value[i].duration;
                }
                if (stage_start_time) elapsed += Date.now() - stage_start_time;
                let remaining = Math.max(total_duration.value - elapsed, 0) / 1000;
                remaining_time.value = remaining.toFixed(1);
            }

            function start_progress() {
                is_active.value = true;
                progress.value = 0;
                current_stage_index.value = 0;
                remaining_interval_id = setInterval(update_remaining_time, 50);
                run_stage();
            }

            function stage_percent_start(index) {
                if (!total_duration.value) return 0;
                const sum_before = stages.value
                    .slice(0, index)
                    .reduce((sum, s) => sum + s.duration, 0);
                return (sum_before / total_duration.value) * 100;
            }

            function stage_percent_end(index) {
                if (!total_duration.value) return 100;
                const sum_to = stages.value
                    .slice(0, index + 1)
                    .reduce((sum, s) => sum + s.duration, 0);
                return (sum_to / total_duration.value) * 100;
            }

            function run_stage() {
                if (current_stage_index.value >= stages.value.length) {
                    finish(false);
                    return;
                }

                const stage = stages.value[current_stage_index.value];

                if (stage.condition) {
                    return;
                }

                if (stage.minigame) {
                    fetch(`https://${GetParentResourceName()}/stageMinigame`, {
                        method: 'POST',
                        body: JSON.stringify({
                            stage_index: current_stage_index.value,
                            stage: stages.value[current_stage_index.value],
                            timestamp: Date.now(),
                        }),
                    });
                }

                stage_start_time = Date.now();

                const sp_start = stage_percent_start(current_stage_index.value);
                const sp_end = stage_percent_end(current_stage_index.value);

                fetch(`https://${GetParentResourceName()}/stageStart`, {
                    method: 'POST',
                    body: JSON.stringify({
                        stage: stages.value[current_stage_index.value],
                        stage_index: current_stage_index.value,
                        timestamp: Date.now(),
                    }),
                });

                clearInterval(interval_id);
                interval_id = setInterval(() => {
                    const elapsed = Date.now() - stage_start_time;
                    const ratio = Math.min(elapsed / stage.duration, 1);
                    progress.value = sp_start + (sp_end - sp_start) * ratio;

                    if (ratio >= 1) {
                        clearInterval(interval_id);
                        interval_id = null;

                        stages.value[current_stage_index.value].finished = true;
                        fetch(`https://${GetParentResourceName()}/stageFinished`, {
                            method: 'POST',
                            body: JSON.stringify({
                                stage_index: current_stage_index.value,
                                stage: stages.value[current_stage_index.value],
                                timestamp: Date.now(),
                            }),
                        });

                        if (current_stage_index.value < stages.value.length - 1) {
                            current_stage_index.value++;
                            run_stage();
                        } else {
                            progress.value = 100;
                            remaining_time.value = 0;
                            finish(false);
                        }
                    }
                }, 80);
            }

            function skip_current_stage() {
                if (interval_id) {
                    clearInterval(interval_id);
                    interval_id = null;
                }
                stage_start_time = null;

                const idx = current_stage_index.value;
                if (stages.value[idx]) {
                    stages.value[idx].finished = true;
                }

                progress.value = stage_percent_end(idx);
                update_remaining_time();

                fetch(`https://${GetParentResourceName()}/stageFinished`, {
                    method: 'POST',
                    body: JSON.stringify({
                        stage_index: idx,
                        stage: stages.value[idx],
                        skipped: true,
                        timestamp: Date.now(),
                    }),
                });

                if (idx < stages.value.length - 1) {
                    current_stage_index.value++;
                    setTimeout(run_stage, 10);
                } else {
                    remaining_time.value = 0;
                    progress.value = 100;
                    finish(false);
                }
            }

            function finish(cancelled) {
                clearInterval(interval_id);
                clearInterval(remaining_interval_id);
                remaining_interval_id = null;
                interval_id = null;
                stage_start_time = null;

                setTimeout(() => {
                    is_active.value = false;

                    fetch(`https://${GetParentResourceName()}/progressFinished`, {
                        method: 'POST',
                        body: JSON.stringify({ cancelled }),
                    });

                    stages.value = {};
                    progress.value = 0;
                    total_duration.value = 0;
                    remaining_time.value = 0;
                }, 250);
            }

            function handle_message(event) {
                const { action, data } = event.data;

                if (action === 'START_PROGRESS') {
                    window_config.value.label = data.label || 'Progress';
                    window_config.value.icon = data.icon || 'fa-solid fa-spinner';
                    window_config.value.theme = data.theme || 'default';
                    window_config.value.position = data.position || 'center-bottom';
                    window_config.value.iconColor = data.iconColor || '#ff4b5c';
                    can_cancel.value = !!data.canCancel;

                    stages.value =
                        data.stages && data.stages.length > 0
                            ? data.stages
                            : [
                                  {
                                      message: data.label || 'Working...',
                                      duration: data.duration || 3000,
                                      progressColor: data.progressColor,
                                  },
                              ];

                    total_duration.value = stages.value.reduce((sum, s) => sum + s.duration, 0);

                    start_progress();
                } else if (action === 'CANCEL') {
                    finish(true);
                } else if (action === 'CONDITIONAL_SKIP') {
                    stages.value[current_stage_index.value].finished = true;
                    fetch(`https://${GetParentResourceName()}/stageFinished`, {
                        method: 'POST',
                        body: JSON.stringify({
                            stage: stages.value[current_stage_index.value],
                            stage_index: current_stage_index.value,
                            timestamp: Date.now(),
                        }),
                    });
                    current_stage_index.value++;
                    run_stage();
                } else if (action === 'MINIGAME_RESULT') {
                    if (
                        data.result === true &&
                        current_stage_index.value === data.stage_index - 1
                    ) {
                        skip_current_stage();
                    } else {
                        let stage = stages.value[current_stage_index.value];
                        fetch(`https://${GetParentResourceName()}/minigameFailed`, {
                            method: 'POST',
                            body: JSON.stringify({
                                stage_index: current_stage_index.value,
                                stage: stage,
                                data,
                                timestamp: Date.now(),
                            }),
                        });

                        if (stage.cancelMode === 'hard') {
                            finish(true);
                        }
                    }
                } else if (action === 'SET_LOCALE') {
                    locale.value = data.locale;
                }
            }

            onMounted(() => {
                window.addEventListener('message', handle_message);
                fetch(`https://${GetParentResourceName()}/ready`, {
                    method: 'POST',
                    body: JSON.stringify({ timestamp: Date.now() }),
                });
            });

            onBeforeUnmount(() => {
                clearInterval(interval_id);
                clearInterval(remaining_interval_id);
                window.removeEventListener('message', handle_message);
            });

            return {
                locale,
                window_config,
                stages,
                progress,
                current_stage_index,
                remaining_time,
                can_cancel,
                is_active,
            };
        },
    }).mount('#app');
}
