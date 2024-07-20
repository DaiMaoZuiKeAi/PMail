package setup

import (
	"github.com/Jinnrry/pmail/signal"
	"github.com/Jinnrry/pmail/utils/errors"
)

// Finish 标记初始化完成
func Finish() error {
	cfg, err := ReadConfig()
	if err != nil {
		return errors.Wrap(err)
	}
	cfg.IsInit = true

	err = WriteConfig(cfg)
	if err != nil {
		return errors.Wrap(err)
	}
	// 初始化完成
	signal.InitChan <- true
	return nil
}
